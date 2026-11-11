"""Periodic FPS/CPU/memory sampler (port of MetricsCollector.cpp).

Runs on its own background QThread (one per open camera session, created by
DiagnosticsManager with the same QThread + moveToThread pattern as the C++
build). A coarse QTimer on that thread samples every tick and emits the
results as signals, delivered to the GUI-thread DiagnosticSession through
queued connections.

Python addition: ``system_metrics`` may be passed to inject a provider (the
C++ class always constructs a SystemMetricsProvider); default is unchanged.
"""

from __future__ import annotations

from typing import Callable

from PyQt5.QtCore import QObject, Qt, QTimer, pyqtSignal, pyqtSlot

from camvistra.diagnostics.diagnostics_data import FpsSample, ResourceSample, now_ms
from camvistra.diagnostics.i_system_metrics_provider import ISystemMetricsProvider
from camvistra.diagnostics.system_metrics_provider import SystemMetricsProvider

DEFAULT_INTERVAL_MS = 750


class MetricsCollector(QObject):
    newFpsSample = pyqtSignal(object)       # FpsSample
    newResourceSample = pyqtSignal(object)  # ResourceSample

    def __init__(self, fps_provider: Callable[[], float] | None, target_fps: float,
                 interval_ms: int = DEFAULT_INTERVAL_MS, parent: QObject | None = None,
                 system_metrics: ISystemMetricsProvider | None = None):
        super().__init__(parent)
        self._fps_provider = fps_provider
        self._target_fps = float(target_fps)
        self._interval_ms = int(interval_ms)
        self._timer: QTimer | None = None
        self._system_metrics = system_metrics if system_metrics is not None else SystemMetricsProvider()

    @pyqtSlot()
    def start(self) -> None:
        # Must run after moveToThread() so the timer is affine to the
        # collector's own thread (DiagnosticsManager invokes it queued).
        if self._timer is not None:
            return
        self._timer = QTimer(self)
        self._timer.setTimerType(Qt.CoarseTimer)
        self._timer.timeout.connect(self._on_tick)
        self._timer.start(self._interval_ms)

    @pyqtSlot()
    def stop(self) -> None:
        if self._timer is not None:
            self._timer.stop()
            self._timer.deleteLater()
            self._timer = None

    @pyqtSlot()
    def _on_tick(self) -> None:
        now = now_ms()

        if self._fps_provider:
            try:
                achieved = float(self._fps_provider())
            except Exception:  # a faulty provider must not kill the sampler
                achieved = 0.0
            self.newFpsSample.emit(FpsSample(now, achieved, self._target_fps))

        self.newResourceSample.emit(ResourceSample(
            now, float(self._system_metrics.get_cpu_percent()),
            int(self._system_metrics.get_memory_bytes())))
