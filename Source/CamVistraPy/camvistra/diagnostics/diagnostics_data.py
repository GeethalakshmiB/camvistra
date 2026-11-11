"""Plain data samples (port of CamVistra/Diagnostics/DiagnosticsData.h).

Buffered by MetricsCollector/DiagnosticSession and consumed by
ChartRenderer/ReportGenerator. The C++ build registers these with
``qRegisterMetaType`` so they can cross the MetricsCollector (background
QThread) -> GUI thread queued-signal boundary; in PyQt the signals carrying
them are declared as ``pyqtSignal(object)``, which needs no registration.
"""

from __future__ import annotations

import time
from dataclasses import dataclass


def now_ms() -> int:
    """Epoch milliseconds (QDateTime::currentMSecsSinceEpoch equivalent)."""
    return time.time_ns() // 1_000_000


@dataclass
class FpsSample:
    timestamp_ms: int = 0
    achieved_fps: float = 0.0
    target_fps: float = 0.0


@dataclass
class ResourceSample:
    timestamp_ms: int = 0
    cpu_percent: float = 0.0
    memory_bytes: int = 0


@dataclass
class LatencySample:
    timestamp_ms: int = 0
    latency_ms: float = 0.0


@dataclass
class ControlEvent:
    """One timestamped device-control change, regardless of which
    IUvcControlProvider adapter produced it (Camsdk / Routecam / WifiOnvif)."""

    timestamp_ms: int = 0
    control_name: str = ""
    value: int = 0
    source_adapter: str = ""  # "Camsdk" | "Routecam" | "WifiOnvif"
