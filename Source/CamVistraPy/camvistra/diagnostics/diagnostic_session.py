"""One open camera session (or 12 h segment) and its buffers
(port of DiagnosticSession.cpp).

Lives on the GUI thread (created/destroyed by DiagnosticsManager).
MetricsCollector (background QThread) and DiagnosticsManager.report_latency_sample
(frame-processing thread) deliver samples through queued connections, so the
buffers are only touched from the GUI thread. Every sample is mirrored to a
SessionFlushWriter for crash recovery; finalize() renders the PDF report and
discards that trail. A 12 h single-shot timer emits ``rolloverDue`` so the
manager can cut the session into a new segment.
"""

from __future__ import annotations

from PyQt5.QtCore import QObject, Qt, QTimer, pyqtSignal, pyqtSlot

from camvistra import tslog
from camvistra.diagnostics import report_generator
from camvistra.diagnostics.diagnostics_data import (
    ControlEvent, FpsSample, LatencySample, ResourceSample, now_ms,
)
from camvistra.diagnostics.session_flush_writer import SessionFlushWriter

# A still-open session reaching this age rolls over into a new segment.
ROLLOVER_INTERVAL_MS = 12 * 60 * 60 * 1000


class DiagnosticSession(QObject):
    rolloverDue = pyqtSignal(str)

    # Internal cross-thread hand-off (QMetaObject::invokeMethod(..., Qt::QueuedConnection)
    # in C++): emitted from any thread, delivered on this object's thread.
    _queuedLatencySample = pyqtSignal(object)
    _queuedLatencyBatch = pyqtSignal(object)
    _queuedFpsSample = pyqtSignal(object)

    def __init__(self, session_key: str, camera_name: str, platform_tag: str, target_fps: float,
                 segment_index: int = 1, previous_segment_file_name: str = "",
                 original_session_start_ms: int = -1, explicit_start_time_ms: int = -1,
                 parent: QObject | None = None):
        super().__init__(parent)
        self._session_key = session_key
        self._camera_name = camera_name
        self._platform_tag = platform_tag
        self._target_fps = float(target_fps)
        self._start_time_ms = int(explicit_start_time_ms) if explicit_start_time_ms >= 0 else now_ms()
        self._segment_index = int(segment_index)
        self._previous_segment_file_name = previous_segment_file_name or ""
        self._original_start_time_ms = (int(original_session_start_ms) if original_session_start_ms >= 0
                                        else self._start_time_ms)

        self.fps_samples: list[FpsSample] = []
        self.resource_samples: list[ResourceSample] = []
        self.latency_samples: list[LatencySample] = []
        # Grouped by control name; control_order keeps first-touched order.
        self.control_events: dict[str, list[ControlEvent]] = {}
        self.control_order: list[str] = []

        self.flush_writer = SessionFlushWriter(session_key, camera_name, platform_tag, target_fps,
                                               self._start_time_ms, self)

        self.rollover_timer = QTimer(self)
        self.rollover_timer.setSingleShot(True)
        self.rollover_timer.timeout.connect(self._on_rollover_timer)
        self.rollover_timer.start(ROLLOVER_INTERVAL_MS)

        self._queuedLatencySample.connect(self.on_latency_sample, Qt.QueuedConnection)
        self._queuedLatencyBatch.connect(self.on_latency_batch, Qt.QueuedConnection)
        self._queuedFpsSample.connect(self.on_fps_sample, Qt.QueuedConnection)

    # --- getters (C++ const accessors) ---
    def session_key(self) -> str:
        return self._session_key

    def camera_name(self) -> str:
        return self._camera_name

    def start_time_ms(self) -> int:
        return self._start_time_ms

    def target_fps(self) -> float:
        return self._target_fps

    def segment_index(self) -> int:
        return self._segment_index

    def original_session_start_ms(self) -> int:
        return self._original_start_time_ms

    # --- slots ---
    @pyqtSlot()
    def _on_rollover_timer(self) -> None:
        self.rolloverDue.emit(self._session_key)

    @pyqtSlot(object)
    def on_fps_sample(self, sample: FpsSample) -> None:
        self.fps_samples.append(sample)
        self.flush_writer.append_fps_sample(sample)

    @pyqtSlot(object)
    def on_resource_sample(self, sample: ResourceSample) -> None:
        self.resource_samples.append(sample)
        self.flush_writer.append_resource_sample(sample)

    @pyqtSlot(object)
    def on_latency_sample(self, sample: LatencySample) -> None:
        self.latency_samples.append(sample)
        self.flush_writer.append_latency_sample(sample)

    @pyqtSlot(object)
    def on_latency_batch(self, samples: list) -> None:
        for sample in samples:
            self.on_latency_sample(sample)

    @pyqtSlot(str, int, "qint64")
    def on_control_changed(self, control_name: str, value: int, timestamp_ms: int) -> None:
        if control_name not in self.control_events:
            self.control_order.append(control_name)
            self.control_events[control_name] = []
        self.control_events[control_name].append(
            ControlEvent(timestamp_ms=int(timestamp_ms), control_name=control_name, value=int(value)))
        self.flush_writer.append_control_event(control_name, value, timestamp_ms)

    # --- finalize ---
    def build_report_input(self, end_time_ms: int, next_segment_file_name: str = "") -> report_generator.ReportInput:
        return report_generator.ReportInput(
            camera_name=self._camera_name,
            platform_tag=self._platform_tag,
            target_fps=self._target_fps,
            start_time_ms=self._start_time_ms,
            end_time_ms=end_time_ms,
            fps_samples=list(self.fps_samples),
            resource_samples=list(self.resource_samples),
            latency_samples=list(self.latency_samples),
            control_sections=[report_generator.ControlSection(name, list(self.control_events.get(name, [])))
                              for name in self.control_order],
            segment_index=self._segment_index,
            previous_segment_file_name=self._previous_segment_file_name,
            next_segment_file_name=next_segment_file_name or "",
            original_session_start_ms=self._original_start_time_ms,
        )

    def finalize(self, next_segment_file_name: str = "") -> str:
        """Render and save this segment's PDF report, log a summary and return
        the report file name ("" on failure). ``next_segment_file_name`` is
        non-empty only for a 12 h rollover cutover."""
        self.rollover_timer.stop()

        inp = self.build_report_input(now_ms(), next_segment_file_name)
        file_name = report_generator.generate(inp)

        detail = (f"session={self._session_key} camera={self._camera_name} platform={self._platform_tag}"
                  f" segment={self._segment_index} durationMs={inp.end_time_ms - self._start_time_ms}"
                  f" fpsSamples={len(self.fps_samples)} resourceSamples={len(self.resource_samples)}"
                  f" latencySamples={len(self.latency_samples)} changedControls={len(self.control_order)}"
                  f" report={file_name}")

        if not file_name:
            # Keep the NDJSON trail so CrashRecoveryScanner can recover this
            # session on the next launch. (C++ writes the pending lines from
            # ~SessionFlushWriter when the session is deleted; done here.)
            tslog.log_critical(0, "report generation failed " + detail)
            self.flush_writer.stop_timer()
            self.flush_writer.flush()
            return ""

        tslog.log_info(0, detail)
        # Clean finalize: the real report now exists, the crash copy is redundant.
        self.flush_writer.discard()
        return file_name
