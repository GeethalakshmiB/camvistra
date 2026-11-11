"""Concrete ISystemMetricsProvider (port of SystemMetricsProvider.cpp).

The C++ class calls the OS directly (Windows: GetProcessTimes +
GetProcessMemoryInfo; Linux: /proc/self/stat utime+stime and
/proc/self/status VmRSS). This port uses psutil, which reads the very same
counters:

* ``Process.cpu_times()`` user+system == kernel+user time (Windows) /
  utime+stime (Linux);
* ``Process.memory_info().rss`` == WorkingSetSize (Windows) / VmRSS (Linux).

The CPU% maths is unchanged: delta process CPU time over delta wall time,
normalised by ``QThread.idealThreadCount()`` and clamped to 0-100. The only
difference is resolution: the wall clock is ``time.monotonic()`` in float ms
instead of QElapsedTimer's integer ms, and CPU time comes in float seconds
instead of 100 ns units / clock ticks.
"""

from __future__ import annotations

import time

import psutil
from PyQt5.QtCore import QThread

from camvistra.diagnostics.i_system_metrics_provider import ISystemMetricsProvider


class SystemMetricsProvider(ISystemMetricsProvider):
    def __init__(self):
        cores = QThread.idealThreadCount()
        self._num_cores = cores if cores > 0 else 1
        self._process = psutil.Process()
        self._last_cpu_seconds = 0.0
        self._have_baseline = False
        self._wall_start = self._now_ms()

    # Overridable time sources (tests substitute deterministic ones).
    def _process_cpu_seconds(self) -> float:
        try:
            t = self._process.cpu_times()
            return float(t.user + t.system)
        except (psutil.Error, OSError):
            return 0.0

    @staticmethod
    def _now_ms() -> float:
        return time.monotonic() * 1000.0

    def get_cpu_percent(self) -> float:
        cpu_now = self._process_cpu_seconds()
        now = self._now_ms()
        wall_ms = now - self._wall_start
        self._wall_start = now

        if not self._have_baseline:
            self._last_cpu_seconds = cpu_now
            self._have_baseline = True
            return 0.0

        cpu_delta = cpu_now - self._last_cpu_seconds if cpu_now >= self._last_cpu_seconds else 0.0
        self._last_cpu_seconds = cpu_now

        if wall_ms <= 0 or self._num_cores <= 0:
            return 0.0

        cpu_ms = cpu_delta * 1000.0
        percent = (cpu_ms / (wall_ms * self._num_cores)) * 100.0
        return min(max(percent, 0.0), 100.0)

    def get_memory_bytes(self) -> int:
        try:
            return int(self._process.memory_info().rss)
        except (psutil.Error, OSError):
            return 0
