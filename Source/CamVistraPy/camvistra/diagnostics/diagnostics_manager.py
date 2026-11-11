"""Process-wide coordinator of all diagnostic sessions (port of DiagnosticsManager.cpp).

A singleton QObject living on the GUI thread, keyed by an opaque session
key each caller defines for its own camera family ("USB:0", "Network:2",
"Routecam", "WifiOnvif"). For every session it owns a GUI-thread
DiagnosticSession plus a MetricsCollector moved onto its own QThread,
connected with queued signals (the HistogramManager pattern of the C++ build).

Threading (same as C++):

* start_session / end_session / shutdown / report_fps_sample are GUI-thread
  calls. ``_sessions`` is guarded by a lock around every access; slow
  session/thread setup and teardown happens outside it.
* report_latency_sample is called from the frame-processing thread
  (30-60x/s per camera): it only does a locked dict lookup and a queued
  signal emit - the sample is appended on the GUI thread.
* report_latency_samples (Python addition) takes a batch of samples
  collected natively by the FramePump and delivers them with one queued
  emit, so the per-frame path does no diagnostics work in Python.

Python additions (defensive, no C++ equivalent):

* report_fps_sample called off the GUI thread is queued like latency
  instead of calling the session directly.
* start_session / end_session / shutdown called off the GUI thread are
  queued to the GUI thread (non-blocking) and logged, instead of creating
  QObjects with the wrong thread affinity.
* ``collector_interval_ms`` / ``system_metrics_factory`` attributes allow
  tests to inject a fast tick and a fake ISystemMetricsProvider.

Lifetime: like the C++ destructor, nothing is finalized at interpreter exit
- shutdown() MUST be called while QApplication is still alive (after
exec_() returns). An atexit hook only flushes the pending NDJSON lines of
sessions still open (what ~SessionFlushWriter does in C++), so they are
recovered on the next launch.
"""

from __future__ import annotations

import atexit
import sys
import threading
from dataclasses import dataclass
from typing import Callable

from PyQt5.QtCore import QCoreApplication, QMetaObject, QObject, Qt, QThread, pyqtSignal, pyqtSlot

from camvistra import tslog
from camvistra.diagnostics import report_generator
from camvistra.diagnostics.diagnostic_session import DiagnosticSession
from camvistra.diagnostics.diagnostics_data import FpsSample, LatencySample, now_ms
from camvistra.diagnostics.metrics_collector import DEFAULT_INTERVAL_MS, MetricsCollector
from camvistra.diagnostics.uvc_control_provider import IUvcControlProvider


def current_platform_tag() -> str:
    return "Windows" if sys.platform == "win32" else "Linux"


@dataclass
class _Entry:
    session: DiagnosticSession | None = None
    collector: MetricsCollector | None = None
    thread: QThread | None = None
    control_provider: IUvcControlProvider | None = None  # not owned

    # Carried forward across a rollover.
    camera_name: str = ""
    target_fps: float = 0.0
    fps_provider: Callable[[], float] | None = None

    # Segment-chain bookkeeping.
    segment_index: int = 1
    original_start_time_ms: int = 0


class DiagnosticsManager(QObject):
    _instance: "DiagnosticsManager | None" = None
    _instance_lock = threading.Lock()

    # Marshals GUI-thread-only calls made from other threads (Python addition).
    _invokeOnGuiThread = pyqtSignal(object)

    @classmethod
    def instance(cls) -> "DiagnosticsManager":
        inst = cls._instance
        if inst is None:
            with cls._instance_lock:
                if cls._instance is None:
                    obj = cls()
                    app = QCoreApplication.instance()
                    if app is not None and obj.thread() != app.thread():
                        # First touched from a worker thread: the manager must
                        # still live on the GUI thread.
                        obj.moveToThread(app.thread())
                    cls._instance = obj
                inst = cls._instance
        return inst

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)
        self._lock = threading.Lock()
        self._sessions: dict[str, _Entry] = {}
        self.collector_interval_ms = DEFAULT_INTERVAL_MS
        self.system_metrics_factory = None  # callable -> ISystemMetricsProvider
        self._invokeOnGuiThread.connect(self._run_invocation, Qt.QueuedConnection)
        atexit.register(self._flush_open_sessions_at_exit)

    # ------------------------------------------------------------------ helpers
    def _on_own_thread(self) -> bool:
        return QThread.currentThread() == self.thread()

    def _defer_to_gui_thread(self, name: str, fn) -> bool:
        if self._on_own_thread():
            return False
        tslog.log_critical(0, f"{name} called off the GUI thread; queued to the GUI thread")
        self._invokeOnGuiThread.emit(fn)
        return True

    @pyqtSlot(object)
    def _run_invocation(self, fn) -> None:
        fn()

    # ------------------------------------------------------------------ public API
    def shutdown(self) -> None:
        """Finalize every still-open session. Call after QApplication.exec_()
        returns, while QApplication is still alive."""
        if self._defer_to_gui_thread("shutdown", self.shutdown):
            return
        with self._lock:
            keys = list(self._sessions.keys())
        for key in keys:
            self.end_session(key)

    def has_session(self, key: str) -> bool:
        with self._lock:
            return key in self._sessions

    def start_session(self, key: str, camera_name: str, nominal_fps: float = 0.0,
                      fps_provider: Callable[[], float] | None = None,
                      control_provider: IUvcControlProvider | None = None) -> None:
        """Start buffering a new session for ``key``. No-op (logged) if one is
        already active - callers must end_session() first."""
        if self._defer_to_gui_thread("start_session", lambda: self.start_session(
                key, camera_name, nominal_fps, fps_provider, control_provider)):
            return
        with self._lock:
            if key in self._sessions:
                tslog.log_critical(0, "startSession called with a session already active for key=" + key)
                return
        self._start_session_internal(key, camera_name, float(nominal_fps), fps_provider, control_provider,
                                     1, "", -1, -1)

    def report_fps_sample(self, key: str, fps: float) -> None:
        """Event-driven FPS feed (models that already emit an fps signal).
        No-op if ``key`` has no active session."""
        with self._lock:
            entry = self._sessions.get(key)
            if entry is None or entry.session is None:
                return
            session = entry.session
            sample = FpsSample(now_ms(), float(fps), session.target_fps())
            if QThread.currentThread() != session.thread():
                session._queuedFpsSample.emit(sample)
                return
        session.on_fps_sample(sample)

    def report_latency_sample(self, key: str, capture_epoch_ms: int) -> None:
        """Capture-to-handoff latency (now - capture_epoch_ms). Safe and cheap
        from any thread; the sample is queued to the session's GUI thread."""
        with self._lock:
            entry = self._sessions.get(key)
            if entry is None or entry.session is None:
                return
            capture = int(capture_epoch_ms)
            # Emitted under the lock: the session cannot be taken out of the
            # map (and deleteLater()'d) while this queued emit is in flight.
            entry.session._queuedLatencySample.emit(LatencySample(capture, float(now_ms() - capture)))

    def report_latency_samples(self, key: str, samples) -> None:
        """Batch form of report_latency_sample: ``samples`` is a sequence of
        (capture_epoch_ms, latency_ms) pairs measured at frame handoff
        (FramePump.takeLatencySamples). One queued emit per batch."""
        if not samples:
            return
        with self._lock:
            entry = self._sessions.get(key)
            if entry is None or entry.session is None:
                return
            batch = [LatencySample(int(capture), float(latency)) for capture, latency in samples]
            entry.session._queuedLatencyBatch.emit(batch)

    def end_session(self, key: str) -> None:
        """Stop sampling, tear down the worker thread and finalize (write the
        PDF report for) the session. No-op if none is active."""
        if self._defer_to_gui_thread("end_session", lambda: self.end_session(key)):
            return
        with self._lock:
            entry = self._sessions.pop(key, None)
        if entry is None:
            return

        self._disconnect_provider(entry)
        self._stop_collector(entry)

        if entry.session is not None:
            entry.session.finalize()
            entry.session.deleteLater()
            entry.session = None

        tslog.log_info(0, "session ended key=" + key)

    # ------------------------------------------------------------------ internals
    def _start_session_internal(self, key: str, camera_name: str, target_fps: float,
                                fps_provider, control_provider, segment_index: int,
                                previous_segment_file_name: str, original_start_time_ms: int,
                                explicit_start_time_ms: int) -> None:
        entry = _Entry(camera_name=camera_name, target_fps=target_fps, fps_provider=fps_provider,
                       control_provider=control_provider, segment_index=segment_index)

        entry.session = DiagnosticSession(key, camera_name, current_platform_tag(), target_fps,
                                          segment_index, previous_segment_file_name,
                                          original_start_time_ms, explicit_start_time_ms, self)
        entry.original_start_time_ms = entry.session.original_session_start_ms()
        entry.session.rolloverDue.connect(self._rollover_session)

        # QThread + worker: moveToThread, queued connections,
        # finished -> deleteLater, start, queued start().
        entry.thread = QThread()
        entry.thread.setObjectName("Diagnostics:" + key)
        metrics = self.system_metrics_factory() if self.system_metrics_factory else None
        entry.collector = MetricsCollector(fps_provider, target_fps, self.collector_interval_ms,
                                           system_metrics=metrics)
        entry.collector.moveToThread(entry.thread)

        entry.collector.newFpsSample.connect(entry.session.on_fps_sample, Qt.QueuedConnection)
        entry.collector.newResourceSample.connect(entry.session.on_resource_sample, Qt.QueuedConnection)
        entry.thread.finished.connect(entry.collector.deleteLater)

        if control_provider is not None:
            control_provider.controlChanged.connect(entry.session.on_control_changed, Qt.QueuedConnection)

        entry.thread.start()
        QMetaObject.invokeMethod(entry.collector, "start", Qt.QueuedConnection)

        with self._lock:
            self._sessions[key] = entry

        tslog.log_info(0, f"session started key={key} camera={camera_name} segment={segment_index}")

    @staticmethod
    def _disconnect_provider(entry: _Entry) -> None:
        if entry.control_provider is not None and entry.session is not None:
            try:
                entry.control_provider.controlChanged.disconnect(entry.session.on_control_changed)
            except (TypeError, RuntimeError):
                pass

    @staticmethod
    def _stop_collector(entry: _Entry) -> None:
        if entry.thread is None:
            return
        QMetaObject.invokeMethod(entry.collector, "stop", Qt.BlockingQueuedConnection)
        entry.thread.quit()
        entry.thread.wait()
        entry.thread = None
        entry.collector = None  # deleted by thread.finished -> deleteLater

    @pyqtSlot(str)
    def _rollover_session(self, key: str) -> None:
        with self._lock:
            old = self._sessions.pop(key, None)
        if old is None:
            return

        now = now_ms()
        next_file_name = report_generator.build_file_name(old.camera_name, now)

        self._disconnect_provider(old)
        self._stop_collector(old)

        finished_file_name = ""
        if old.session is not None:
            finished_file_name = old.session.finalize(next_file_name)
            old.session.deleteLater()
            old.session = None

        tslog.log_info(0, f"session rolled over after 12h key={key} previousReport={finished_file_name}")

        # The camera itself was never touched: start the next segment now.
        self._start_session_internal(key, old.camera_name, old.target_fps, old.fps_provider,
                                     old.control_provider, old.segment_index + 1, finished_file_name,
                                     old.original_start_time_ms, now)

    def _flush_open_sessions_at_exit(self) -> None:
        try:
            with self._lock:
                entries = list(self._sessions.values())
            for entry in entries:
                if entry.session is not None:
                    try:
                        entry.session.flush_writer.flush()
                    except Exception:
                        pass
        except Exception:
            pass
