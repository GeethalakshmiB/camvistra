"""Crash-resilience NDJSON trail for one open session (port of SessionFlushWriter.cpp).

Every sample/control event is appended to an in-memory buffer; a QTimer
batches that buffer out to ``<reports>/.partial/<key>_<startMs>.ndjson``
every 30 s, so a crash loses at most one flush interval of data. On a clean
finalize DiagnosticSession calls :meth:`discard` and the file is deleted;
CrashRecoveryScanner only ever sees files from sessions that never finished.

Line format matches ``QJsonDocument(obj).toJson(QJsonDocument::Compact)``:
keys sorted (QJsonObject keeps them sorted), no whitespace, UTF-8,
integral doubles written without a fraction (``30`` not ``30.0``),
non-finite numbers as ``null``. For example::

    {"cameraName":"cam","platformTag":"Windows","sessionKey":"USB:0","startTimeMs":1000,"targetFps":30,"type":"session"}
    {"achievedFps":29.5,"targetFps":30,"timestampMs":3100,"type":"fps"}

Lives on the GUI thread next to its DiagnosticSession. The pending buffer is
swapped atomically in :meth:`flush`, so appends from another thread cannot
corrupt it (the C++ class relies purely on single-thread use).

The C++ destructor flushes pending lines; Python has no deterministic
destructor, so owners call :meth:`flush` explicitly where C++ would have
destroyed the object (see DiagnosticSession.finalize and the manager's
atexit hook).
"""

from __future__ import annotations

import json
import math
import os
import re

from PyQt5.QtCore import QObject, QTimer, pyqtSlot

from camvistra import tslog
from camvistra.diagnostics import report_paths
from camvistra.diagnostics.diagnostics_data import FpsSample, LatencySample, ResourceSample

# 30 s: bounds crash data loss without turning every sample into a disk write.
FLUSH_INTERVAL_MS = 30000

_UNSAFE_KEY_CHARS = re.compile(r"[^A-Za-z0-9_-]")


def sanitize_for_filename(key: str) -> str:
    return _UNSAFE_KEY_CHARS.sub("_", key)


def _json_value(v):
    if isinstance(v, bool) or v is None or isinstance(v, str):
        return v
    if isinstance(v, float):
        if not math.isfinite(v):
            return None
        if v.is_integer() and abs(v) < 2 ** 53:
            return int(v)
    return v


def to_line(obj: dict) -> str:
    """Serialize one record exactly like QJsonDocument::Compact."""
    return json.dumps({k: _json_value(v) for k, v in obj.items()}, sort_keys=True,
                      separators=(",", ":"), ensure_ascii=False)


class SessionFlushWriter(QObject):
    def __init__(self, session_key: str, camera_name: str, platform_tag: str,
                 target_fps: float, start_time_ms: int, parent: QObject | None = None):
        super().__init__(parent)
        self.file_path = (report_paths.partial_directory() + "/" + sanitize_for_filename(session_key)
                          + "_" + str(int(start_time_ms)) + ".ndjson")
        self.pending_lines: list[str] = [to_line({
            "type": "session",
            "sessionKey": session_key,
            "cameraName": camera_name,
            "platformTag": platform_tag,
            "targetFps": float(target_fps),
            "startTimeMs": float(start_time_ms),
        })]

        self.timer = QTimer(self)
        self.timer.timeout.connect(self._on_timer)
        self.timer.start(FLUSH_INTERVAL_MS)

    def append_fps_sample(self, sample: FpsSample) -> None:
        self.pending_lines.append(to_line({
            "type": "fps",
            "timestampMs": float(sample.timestamp_ms),
            "achievedFps": float(sample.achieved_fps),
            "targetFps": float(sample.target_fps),
        }))

    def append_resource_sample(self, sample: ResourceSample) -> None:
        self.pending_lines.append(to_line({
            "type": "resource",
            "timestampMs": float(sample.timestamp_ms),
            "cpuPercent": float(sample.cpu_percent),
            "memoryBytes": float(sample.memory_bytes),
        }))

    def append_latency_sample(self, sample: LatencySample) -> None:
        self.pending_lines.append(to_line({
            "type": "latency",
            "timestampMs": float(sample.timestamp_ms),
            "latencyMs": float(sample.latency_ms),
        }))

    def append_control_event(self, control_name: str, value: int, timestamp_ms: int) -> None:
        self.pending_lines.append(to_line({
            "type": "control",
            "timestampMs": float(timestamp_ms),
            "controlName": control_name,
            "value": int(value),
        }))

    @pyqtSlot()
    def _on_timer(self) -> None:
        self.flush()

    def flush(self) -> None:
        """Write any buffered lines to disk immediately."""
        if not self.pending_lines:
            return
        lines, self.pending_lines = self.pending_lines, []
        try:
            # Text mode + '\n' -> CRLF on Windows, like QIODevice::Text.
            with open(self.file_path, "a", encoding="utf-8") as f:
                for line in lines:
                    f.write(line + "\n")
        except OSError:
            # C++ keeps the lines pending when the open fails.
            self.pending_lines[:0] = lines
            tslog.log_critical(0, "failed to open partial diagnostics file for append: " + self.file_path)

    def discard(self) -> None:
        """Clean-finalize path: drop pending lines, stop the timer, delete the file."""
        self.pending_lines = []
        if self.timer is not None:
            try:
                self.timer.stop()
            except RuntimeError:  # C++ timer already gone
                pass
        try:
            os.remove(self.file_path)
        except OSError:  # QFile::remove semantics: missing file is not an error
            pass

    def stop_timer(self) -> None:
        if self.timer is not None:
            try:
                self.timer.stop()
            except RuntimeError:
                pass

