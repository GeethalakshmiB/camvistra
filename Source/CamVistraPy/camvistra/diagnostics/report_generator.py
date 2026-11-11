"""Standardized PDF diagnostics report (port of ReportGenerator.cpp).

QPdfWriter (A4, 72 DPI so painter units == points, 15 mm margins) +
QPainter, with charts from chart_renderer. Used identically by a normal
close, a 12 h rollover cutover and crash recovery; the callers differ only
in which optional ReportInput fields they fill in. Must run on the GUI
thread (QPixmap/QtCharts).

Layout, fonts, colours, texts and spacing are the C++ values. As in C++,
text heights are measured with a device-less QFontMetrics (screen DPI) and
fractional point sizes are truncated to int (the C++ QFont(QString, int)
constructor does the same implicitly).
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Callable, Sequence

from PyQt5.QtCore import QDateTime, QMarginsF, QPointF, QRect, QRectF, QSize, Qt
from PyQt5.QtGui import (
    QBrush, QColor, QFont, QFontMetrics, QPageLayout, QPageSize, QPainter, QPdfWriter, QPen, QPixmap,
)

from camvistra import tslog
from camvistra.diagnostics import chart_renderer, report_paths
from camvistra.diagnostics.diagnostics_data import (
    ControlEvent, FpsSample, LatencySample, ResourceSample,
)

# One fixed colour per control for the duration of a session; cycles.
CONTROL_PALETTE = (
    QColor(0xEB, 0x68, 0x34),  # orange
    QColor(0x4A, 0x3A, 0xA7),  # violet
    QColor(0x1B, 0xAF, 0x7A),  # aqua
    QColor(0xD0, 0x3B, 0x3B),  # crimson
    QColor(0x2A, 0x78, 0xD6),  # blue
    QColor(0x0C, 0xA3, 0x0C),  # green
)

INK = QColor(0x0B, 0x0B, 0x0B)
INK2 = QColor(0x52, 0x51, 0x4E)
MUTED = QColor(0x89, 0x87, 0x81)
GRID = QColor(0xE1, 0xE0, 0xD9)
BLUE = QColor(0x2A, 0x78, 0xD6)
ORANGE = QColor(0xEB, 0x68, 0x34)
VIOLET = QColor(0x4A, 0x3A, 0xA7)
HEADER_FILL = QColor(0x2A, 0x78, 0xD6)
ROW_STRIPE = QColor(0xEE, 0xED, 0xE9)

CHART_SIZE = QSize(1600, 560)


@dataclass
class ControlSection:
    control_name: str = ""
    events: list[ControlEvent] = field(default_factory=list)


@dataclass
class ReportInput:
    camera_name: str = ""
    platform_tag: str = ""
    target_fps: float = 0.0
    start_time_ms: int = 0
    end_time_ms: int = 0

    fps_samples: list[FpsSample] = field(default_factory=list)
    resource_samples: list[ResourceSample] = field(default_factory=list)
    latency_samples: list[LatencySample] = field(default_factory=list)
    control_sections: list[ControlSection] = field(default_factory=list)  # first-touched order

    # Segment-chain context; defaults describe a normal single-segment session.
    segment_index: int = 1
    previous_segment_file_name: str = ""
    next_segment_file_name: str = ""
    original_session_start_ms: int = 0

    # Crash-recovery context.
    recovered_after_crash: bool = False


def sanitize_file_name_part(name: str) -> str:
    s = re.sub(r'[\\/:*?"<>|#&{}]', "_", name)
    s = s.replace(" ", "_")
    s = re.sub(r"_+", "_", s)
    s = re.sub(r"^_+|_+$", "", s)
    if len(s) > 40:
        s = s[:40]
    return s or "camera"


def _cdiv(a: int, b: int) -> int:
    """C++ integer division (truncates toward zero)."""
    q = abs(a) // b
    return q if a >= 0 else -q


def _cmod(a: int, b: int) -> int:
    return a - b * _cdiv(a, b)


def format_duration(ms: int) -> str:
    total_seconds = _cdiv(int(ms), 1000)
    hours = _cdiv(total_seconds, 3600)
    minutes = _cdiv(_cmod(total_seconds, 3600), 60)
    seconds = _cmod(total_seconds, 60)
    return f"{hours}h {minutes:02d}m {seconds:02d}s"


def compute_stats(values: Sequence, accessor: Callable) -> tuple[float, float, float]:
    """(avg, min, max) of accessor(item); all 0 for an empty sequence."""
    if not values:
        return 0.0, 0.0, 0.0
    data = [float(accessor(v)) for v in values]
    return sum(data) / len(data), min(data), max(data)


def _iso(ms: int) -> str:
    return QDateTime.fromMSecsSinceEpoch(int(ms)).toString(Qt.ISODate)


def _f1(v: float) -> str:
    return f"{v:.1f}"


class _Layout:
    """Draw calls onto one QPdfWriter/QPainter pair, with the header/footer
    band on every page and non-splitting block page breaks."""

    def __init__(self, writer: QPdfWriter, painter: QPainter, camera_name: str, platform_tag: str):
        self._writer = writer
        self._painter = painter
        self._camera_name = camera_name
        self._platform_tag = platform_tag
        page_rect = writer.pageLayout().paintRectPixels(writer.resolution())
        self._content_width = float(page_rect.width())
        self._content_height = float(page_rect.height())
        self._top = 20.0
        self._bottom = self._content_height - 16.0
        self._cursor_y = 0.0
        self.page_number = 1
        self._start_page()

    def content_width(self) -> float:
        return self._content_width

    def cursor_y(self) -> float:
        return self._cursor_y

    def advance(self, dy: float) -> None:
        self._cursor_y += dy

    def ensure_space(self, needed_height: float) -> None:
        if self._cursor_y + needed_height > self._bottom:
            self._new_page()

    def section_title(self, text: str, color: QColor = BLUE) -> None:
        p = self._painter
        font = QFont("Helvetica", 15, QFont.Bold)
        text_h = QFontMetrics(font).height()
        self.ensure_space(text_h + 10)
        p.setFont(font)
        p.setPen(color)
        p.drawText(QRectF(0, self._cursor_y, self._content_width, text_h),
                   int(Qt.AlignLeft | Qt.AlignVCenter), text)
        self._cursor_y += text_h + 3
        p.setPen(QPen(QBrush(color), 1.4))
        p.drawLine(QPointF(0, self._cursor_y), QPointF(34, self._cursor_y))
        self._cursor_y += 8

    def sub_heading(self, text: str, color: QColor = INK) -> None:
        p = self._painter
        font = QFont("Helvetica", 11, QFont.Bold)
        text_h = QFontMetrics(font).height()
        self.ensure_space(text_h + 6)
        p.setFont(font)
        p.setPen(color)
        p.drawText(QRectF(0, self._cursor_y, self._content_width, text_h),
                   int(Qt.AlignLeft | Qt.AlignVCenter), text)
        self._cursor_y += text_h + 5

    def paragraph(self, text: str, color: QColor = INK2, point_size: float = 9, italic: bool = False) -> None:
        p = self._painter
        font = QFont("Helvetica", int(point_size), QFont.Normal, italic)
        h = self._text_height(text, font)
        self.ensure_space(h + 4)
        p.setFont(font)
        p.setPen(color)
        p.drawText(QRectF(0, self._cursor_y, self._content_width, h), int(Qt.TextWordWrap), text)
        self._cursor_y += h + 4

    def chart_block(self, heading: str, heading_color: QColor, chart: QPixmap, caption: str) -> None:
        """Heading + chart + caption as one unit that never splits across pages."""
        chart_h = self._content_width * 0.34
        cap_h = self._text_height(caption, QFont("Helvetica", 9))
        heading_h = QFontMetrics(QFont("Helvetica", 11, QFont.Bold)).height()
        total = heading_h + 11 + chart_h + 4 + cap_h + 6

        self.ensure_space(total)
        self.sub_heading(heading, heading_color)
        self._painter.drawPixmap(QRectF(0, self._cursor_y, self._content_width, chart_h), chart,
                                 QRectF(chart.rect()))
        self._cursor_y += chart_h + 4
        self.paragraph(caption)
        self._cursor_y += 2

    def table(self, headers: Sequence[str], rows: Sequence[Sequence[str]], col_widths: Sequence[float]) -> None:
        p = self._painter
        header_font = QFont("Helvetica", 9, QFont.Bold)
        body_font = QFont("Helvetica", 8)  # C++ passes 8.6 to an int parameter
        row_h = max(QFontMetrics(header_font).height(), QFontMetrics(body_font).height()) + 5
        self.ensure_space(row_h * (len(rows) + 1))

        p.setFont(header_font)
        x = 0.0
        p.fillRect(QRectF(0, self._cursor_y, self._content_width, row_h), HEADER_FILL)
        p.setPen(QColor(Qt.white))
        for i, header in enumerate(headers):
            p.drawText(QRectF(x + 2, self._cursor_y, col_widths[i] - 4, row_h), int(Qt.AlignVCenter), header)
            x += col_widths[i]
        self._cursor_y += row_h

        p.setFont(body_font)
        for r, row in enumerate(rows):
            self.ensure_space(row_h)
            if r % 2 == 1:
                p.fillRect(QRectF(0, self._cursor_y, self._content_width, row_h), ROW_STRIPE)
            x = 0.0
            p.setPen(INK2)
            for i, cell in enumerate(row):
                p.drawText(QRectF(x + 2, self._cursor_y, col_widths[i] - 4, row_h), int(Qt.AlignVCenter), cell)
                x += col_widths[i]
            p.setPen(GRID)
            p.drawLine(QPointF(0, self._cursor_y + row_h), QPointF(self._content_width, self._cursor_y + row_h))
            self._cursor_y += row_h
        self._cursor_y += 4

    def _text_height(self, text: str, font: QFont) -> float:
        bounds = QFontMetrics(font).boundingRect(QRect(0, 0, int(self._content_width), 1000000),
                                                 int(Qt.TextWordWrap), text)
        return float(bounds.height())

    def _start_page(self) -> None:
        p = self._painter
        p.setFont(QFont("Helvetica", 8))  # C++: 8.3 truncated to int
        p.setPen(MUTED)
        p.drawText(QRectF(0, 4, self._content_width - 60, 8), int(Qt.AlignLeft | Qt.AlignVCenter),
                   f"{self._camera_name} - Analytics Report ({self._platform_tag})")
        p.drawText(QRectF(self._content_width - 60, 4, 60, 8), int(Qt.AlignRight | Qt.AlignVCenter),
                   f"Page {self.page_number}")
        p.setPen(GRID)
        p.drawLine(QPointF(0, 14), QPointF(self._content_width, 14))
        p.drawLine(QPointF(0, self._bottom + 2), QPointF(self._content_width, self._bottom + 2))
        self._cursor_y = self._top

    def _new_page(self) -> None:
        self._writer.newPage()
        self.page_number += 1
        self._start_page()


def build_file_name(camera_name: str, start_time_ms: int) -> str:
    """``<camera>_analytics_report_<yyyyMMdd_HHmmss>.pdf`` (local time).

    CamVistra names its reports "analytics"; the C++ build writes
    ``<camera>_diagnostic_report_...``.
    """
    timestamp = QDateTime.fromMSecsSinceEpoch(int(start_time_ms)).toString("yyyyMMdd_HHmmss")
    return f"{sanitize_file_name_part(camera_name)}_analytics_report_{timestamp}.pdf"


def build_summary(inp: ReportInput) -> str:
    summary = (f"Camera: {inp.camera_name}  |  Platform: {inp.platform_tag}  |  "
               f"Session start: {_iso(inp.start_time_ms)}  |  "
               f"Duration: {format_duration(inp.end_time_ms - inp.start_time_ms)}")
    if inp.recovered_after_crash:
        summary += ("\n\nRecovered after abnormal termination - session end time reflects the last periodic "
                    "safety flush, not an explicit camera close.")
    if inp.segment_index > 1:
        summary += (f"\n\nSegment {inp.segment_index} of a session started at "
                    f"{_iso(inp.original_session_start_ms)}; previous segment: "
                    f"{inp.previous_segment_file_name or '(unknown)'}.")
    if inp.next_segment_file_name:
        summary += f"\n\nSession continued past 12h - see {inp.next_segment_file_name} for the following segment."
    return summary


def generate(inp: ReportInput) -> str:
    """Render the PDF into reports_directory(); return the file name (not the
    full path), or "" on failure (logged)."""
    file_name = build_file_name(inp.camera_name, inp.start_time_ms)
    file_path = report_paths.reports_directory() + "/" + file_name

    writer = QPdfWriter(file_path)
    writer.setPageSize(QPageSize(QPageSize.A4))
    # 72 DPI: painter coordinates == points, so font point sizes and
    # QFontMetrics heights map 1:1 onto drawing units.
    writer.setResolution(72)
    writer.setPageMargins(QMarginsF(15, 15, 15, 15), QPageLayout.Millimeter)

    painter = QPainter()
    if not painter.begin(writer):
        tslog.log_critical(0, "failed to open PDF report for writing: " + file_path)
        return ""

    try:
        _render(writer, painter, inp)
    except Exception as exc:  # Python-only failure mode; C++ cannot throw here
        painter.end()
        tslog.log_critical(0, f"failed to render PDF report {file_path}: {exc!r}")
        return ""
    painter.end()

    tslog.log_info(0, "analytics report written: " + file_path)
    return file_name


def _render(writer: QPdfWriter, painter: QPainter, inp: ReportInput) -> None:
    layout = _Layout(writer, painter, inp.camera_name, inp.platform_tag)

    # ---- Executive summary ----
    layout.section_title("Runtime Analytics Report", BLUE)
    layout.paragraph(build_summary(inp), INK2, 9.5)

    # ---- Key metrics table ----
    layout.sub_heading("Key Metrics", BLUE)

    fps_avg, fps_min, fps_max = compute_stats(inp.fps_samples, lambda s: s.achieved_fps)
    cpu_avg, cpu_min, cpu_max = compute_stats(inp.resource_samples, lambda s: s.cpu_percent)
    mem_avg, mem_min, mem_max = compute_stats(inp.resource_samples, lambda s: s.memory_bytes / (1024.0 * 1024.0))
    lat_avg, lat_min, lat_max = compute_stats(inp.latency_samples, lambda s: s.latency_ms)

    rows = [
        ["FPS (achieved)", _f1(fps_avg), _f1(fps_min), _f1(fps_max)],
        ["CPU (%)", _f1(cpu_avg), _f1(cpu_min), _f1(cpu_max)],
        ["Memory (MB)", _f1(mem_avg), _f1(mem_min), _f1(mem_max)],
    ]
    if inp.latency_samples:
        rows.append(["Latency (ms)", _f1(lat_avg), _f1(lat_min), _f1(lat_max)])
    cw = layout.content_width()
    layout.table(["Metric", "Avg", "Min", "Max"], rows, [cw * 0.4, cw * 0.2, cw * 0.2, cw * 0.2])

    # ---- FPS ----
    if inp.fps_samples:
        layout.chart_block("FPS", BLUE,
                           chart_renderer.render_fps_chart(inp.fps_samples, inp.start_time_ms, CHART_SIZE),
                           f"Achieved FPS averaged {_f1(fps_avg)} (range {_f1(fps_min)}-{_f1(fps_max)}) "
                           "over the session.")

    # ---- Latency ----
    if inp.latency_samples:
        layout.chart_block("Latency", QColor(0xD0, 0x3B, 0x3B),
                           chart_renderer.render_latency_chart(inp.latency_samples, inp.start_time_ms, CHART_SIZE),
                           f"Capture-to-render latency averaged {_f1(lat_avg)} ms "
                           f"(range {_f1(lat_min)}-{_f1(lat_max)} ms).")

    # ---- CPU / Memory ----
    if inp.resource_samples:
        layout.chart_block("CPU", QColor(0x1B, 0xAF, 0x7A),
                           chart_renderer.render_cpu_chart(inp.resource_samples, inp.start_time_ms, CHART_SIZE),
                           f"Process CPU usage averaged {_f1(cpu_avg)}% (range {_f1(cpu_min)}%-{_f1(cpu_max)}%).")
        layout.chart_block("Memory", VIOLET,
                           chart_renderer.render_memory_chart(inp.resource_samples, inp.start_time_ms, CHART_SIZE),
                           f"Process memory averaged {_f1(mem_avg)} MB (range {_f1(mem_min)}-{_f1(mem_max)} MB).")

    # ---- Per-control sections, first-touched order ----
    for i, section in enumerate(inp.control_sections):
        if not section.events:
            continue
        color = CONTROL_PALETTE[i % len(CONTROL_PALETTE)]
        last = section.events[-1]
        layout.chart_block(section.control_name, ORANGE,
                           chart_renderer.render_control_chart(section.events, inp.start_time_ms, color, CHART_SIZE),
                           f"Changed {len(section.events)} time(s); last value {last.value} "
                           f"at {_iso(last.timestamp_ms)}.")
