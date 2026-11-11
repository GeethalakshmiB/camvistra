"""Per-metric/per-control chart rendering (port of ChartRenderer.cpp).

Renders QtCharts (PyQtChart) charts to off-screen QPixmaps sized for
embedding into the PDF. Pure functions; must run on the GUI thread
(QChart is a QGraphicsWidget) - ReportGenerator, the only caller, does.
The chart is rendered through a QGraphicsScene rather than a widget grab,
so the result is independent of HiDPI scaling, exactly like the C++ code.
"""

from __future__ import annotations

from typing import Sequence

from PyQt5.QtChart import QChart, QLineSeries, QValueAxis
from PyQt5.QtCore import QMargins, QRectF, QSize, QSizeF, Qt
from PyQt5.QtGui import QBrush, QColor, QFont, QPainter, QPen, QPixmap
from PyQt5.QtWidgets import QGraphicsScene

from camvistra.diagnostics.diagnostics_data import (
    ControlEvent, FpsSample, LatencySample, ResourceSample,
)

FPS_COLOR = QColor(0x2A, 0x78, 0xD6)
TARGET_COLOR = QColor(0x89, 0x87, 0x81)
LATENCY_COLOR = QColor(0xD0, 0x3B, 0x3B)
CPU_COLOR = QColor(0x1B, 0xAF, 0x7A)
MEMORY_COLOR = QColor(0x4A, 0x3A, 0xA7)

AXIS_LINE_COLOR = QColor(0x3C, 0x3C, 0x3C)
GRID_LINE_COLOR = QColor(0xCC, 0xCC, 0xCC)

# Charts are rendered ~3x larger than their destination rect on the page,
# so pens/fonts are deliberately oversized to survive the downscale.
SERIES_PEN_WIDTH = 6
AXIS_PEN_WIDTH = 4
GRID_PEN_WIDTH = 2
AXIS_LABEL_POINT_SIZE = 15
AXIS_TITLE_POINT_SIZE = 16
LEGEND_POINT_SIZE = 14


def _elapsed_seconds(timestamp_ms: int, session_start_ms: int) -> float:
    return (timestamp_ms - session_start_ms) / 1000.0


def _series_pen(color: QColor) -> QPen:
    pen = QPen(QBrush(color), SERIES_PEN_WIDTH)
    pen.setCapStyle(Qt.RoundCap)
    pen.setJoinStyle(Qt.RoundJoin)
    return pen


def _style_axes(chart: QChart) -> None:
    label_font = QFont("Helvetica", AXIS_LABEL_POINT_SIZE)
    title_font = QFont("Helvetica", AXIS_TITLE_POINT_SIZE, QFont.Bold)

    for axis in chart.axes():
        axis.setLinePen(QPen(QBrush(AXIS_LINE_COLOR), AXIS_PEN_WIDTH))
        axis.setLabelsFont(label_font)
        axis.setLabelsColor(AXIS_LINE_COLOR)
        axis.setTitleFont(title_font)
        axis.setTitleBrush(QBrush(AXIS_LINE_COLOR))
        if isinstance(axis, QValueAxis):
            axis.setGridLineVisible(True)
            axis.setGridLinePen(QPen(QBrush(GRID_LINE_COLOR), GRID_PEN_WIDTH))

    legend = chart.legend()
    if legend is not None:
        legend.setFont(QFont("Helvetica", LEGEND_POINT_SIZE))
        legend.setLabelColor(AXIS_LINE_COLOR)


def _grab_chart(chart: QChart, size: QSize) -> QPixmap:
    _style_axes(chart)

    chart.legend().setVisible(len(chart.series()) > 1)
    chart.legend().setAlignment(Qt.AlignBottom)
    chart.setMargins(QMargins(10, 10, 10, 10))
    chart.setBackgroundRoundness(0)
    chart.setBackgroundVisible(False)
    chart.resize(QSizeF(size))

    # The scene takes ownership of the chart (and its axes/series) and
    # deletes it when it goes out of scope, as in the C++ code.
    scene = QGraphicsScene()
    scene.addItem(chart)

    pixmap = QPixmap(size)
    pixmap.fill(Qt.white)
    painter = QPainter(pixmap)
    painter.setRenderHint(QPainter.Antialiasing)
    target = QRectF(0, 0, size.width(), size.height())
    scene.render(painter, target, target)
    painter.end()
    return pixmap


def _add_axis_x(chart: QChart, title: str = "Elapsed (s)") -> QValueAxis:
    axis_x = QValueAxis()
    axis_x.setTitleText(title)
    axis_x.setLabelFormat("%.0f")
    chart.addAxis(axis_x, Qt.AlignBottom)
    return axis_x


def _add_axis_y(chart: QChart, title: str) -> QValueAxis:
    axis_y = QValueAxis()
    axis_y.setTitleText(title)
    chart.addAxis(axis_y, Qt.AlignLeft)
    return axis_y


def _single_series_chart(points, color: QColor, y_title: str, size: QSize) -> QPixmap:
    chart = QChart()
    series = QLineSeries()
    series.setPen(_series_pen(color))
    for x, y in points:
        series.append(x, y)
    chart.addSeries(series)
    axis_x = _add_axis_x(chart)
    axis_y = _add_axis_y(chart, y_title)
    series.attachAxis(axis_x)
    series.attachAxis(axis_y)
    return _grab_chart(chart, size)


def render_fps_chart(samples: Sequence[FpsSample], session_start_ms: int, size: QSize) -> QPixmap:
    """Achieved FPS always; target only when at least one sample has one."""
    chart = QChart()
    has_target = any(s.target_fps > 0.0 for s in samples)

    achieved = QLineSeries()
    achieved.setName("Achieved FPS")
    achieved.setPen(_series_pen(FPS_COLOR))

    target = None
    if has_target:
        target = QLineSeries()
        target.setName("Target FPS")
        target.setPen(_series_pen(TARGET_COLOR))

    for s in samples:
        t = _elapsed_seconds(s.timestamp_ms, session_start_ms)
        achieved.append(t, s.achieved_fps)
        if target is not None:
            target.append(t, s.target_fps)

    chart.addSeries(achieved)
    if target is not None:
        chart.addSeries(target)

    axis_x = _add_axis_x(chart)
    axis_y = _add_axis_y(chart, "FPS")
    achieved.attachAxis(axis_x)
    achieved.attachAxis(axis_y)
    if target is not None:
        target.attachAxis(axis_x)
        target.attachAxis(axis_y)

    return _grab_chart(chart, size)


def render_latency_chart(samples: Sequence[LatencySample], session_start_ms: int, size: QSize) -> QPixmap:
    return _single_series_chart(
        ((_elapsed_seconds(s.timestamp_ms, session_start_ms), s.latency_ms) for s in samples),
        LATENCY_COLOR, "Latency (ms)", size)


def render_cpu_chart(samples: Sequence[ResourceSample], session_start_ms: int, size: QSize) -> QPixmap:
    return _single_series_chart(
        ((_elapsed_seconds(s.timestamp_ms, session_start_ms), s.cpu_percent) for s in samples),
        CPU_COLOR, "CPU (%)", size)


def render_memory_chart(samples: Sequence[ResourceSample], session_start_ms: int, size: QSize) -> QPixmap:
    """Memory samples are bytes; rendered in MB."""
    return _single_series_chart(
        ((_elapsed_seconds(s.timestamp_ms, session_start_ms), s.memory_bytes / (1024.0 * 1024.0))
         for s in samples),
        MEMORY_COLOR, "Memory (MB)", size)


def step_points(events: Sequence[ControlEvent], session_start_ms: int) -> list[tuple[float, float]]:
    """Manual step construction: a horizontal-then-vertical point pair at every
    change so the line reads as discrete values, not a slanted interpolation."""
    points: list[tuple[float, float]] = []
    first = True
    last_value = 0.0
    for e in events:
        t = _elapsed_seconds(e.timestamp_ms, session_start_ms)
        if not first:
            points.append((t, last_value))
        points.append((t, float(e.value)))
        last_value = float(e.value)
        first = False
    return points


def render_control_chart(events: Sequence[ControlEvent], session_start_ms: int,
                         control_color: QColor, size: QSize) -> QPixmap:
    return _single_series_chart(step_points(events, session_start_ms), control_color, "Value", size)
