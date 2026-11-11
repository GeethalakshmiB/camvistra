"""Startup recovery of orphaned session trails (port of CrashRecoveryScanner.cpp).

Call :func:`scan_for_orphaned_sessions` once at startup, after QApplication
exists and before any camera is opened (main.cpp does it right after the
qRegisterMetaType calls). Every ``*.ndjson`` left in ``<reports>/.partial/``
by a session that never reached finalize() (crash/kill) is rendered as a
"Recovered after abnormal termination" report and then deleted. Files
without a usable header are deleted; files whose report fails to render
are kept for a retry on the next launch.

JSON value coercion follows QJsonValue (toString/toDouble/toInt with
defaults), so the same files recover identically in both builds.
"""

from __future__ import annotations

import json
import os

from camvistra import tslog
from camvistra.diagnostics import report_generator, report_paths
from camvistra.diagnostics.diagnostics_data import (
    ControlEvent, FpsSample, LatencySample, ResourceSample,
)


def _is_number(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _to_string(v) -> str:
    return v if isinstance(v, str) else ""


def _to_double(v) -> float:
    return float(v) if _is_number(v) else 0.0


def _to_int(v) -> int:
    # QJsonValue::toInt: only integral numbers in int range convert; else 0.
    if _is_number(v):
        f = float(v)
        if f.is_integer() and -2 ** 31 <= f < 2 ** 31:
            return int(f)
    return 0


def parse_orphaned_file(file_path: str) -> tuple[report_generator.ReportInput, int]:
    """Parse one NDJSON trail into a ReportInput (+ last sample timestamp).
    Malformed lines (a crash mid-write) are skipped."""
    inp = report_generator.ReportInput(recovered_after_crash=True)
    last_ts = 0
    control_index: dict[str, int] = {}

    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return inp, last_ts

    for line in lines:
        try:
            obj = json.loads(line)
        except (ValueError, RecursionError):
            continue
        if not isinstance(obj, dict):
            continue

        kind = _to_string(obj.get("type"))
        ts = int(_to_double(obj.get("timestampMs")))
        if kind == "session":
            inp.camera_name = _to_string(obj.get("cameraName"))
            inp.platform_tag = _to_string(obj.get("platformTag"))
            inp.target_fps = _to_double(obj.get("targetFps"))
            inp.start_time_ms = int(_to_double(obj.get("startTimeMs")))
            inp.original_session_start_ms = inp.start_time_ms
        elif kind == "fps":
            inp.fps_samples.append(FpsSample(ts, _to_double(obj.get("achievedFps")),
                                             _to_double(obj.get("targetFps"))))
            last_ts = max(last_ts, ts)
        elif kind == "resource":
            inp.resource_samples.append(ResourceSample(ts, _to_double(obj.get("cpuPercent")),
                                                       int(_to_double(obj.get("memoryBytes")))))
            last_ts = max(last_ts, ts)
        elif kind == "latency":
            inp.latency_samples.append(LatencySample(ts, _to_double(obj.get("latencyMs"))))
            last_ts = max(last_ts, ts)
        elif kind == "control":
            event = ControlEvent(timestamp_ms=ts, control_name=_to_string(obj.get("controlName")),
                                 value=_to_int(obj.get("value")))
            last_ts = max(last_ts, ts)
            idx = control_index.get(event.control_name)
            if idx is None:
                inp.control_sections.append(report_generator.ControlSection(event.control_name, []))
                idx = control_index[event.control_name] = len(inp.control_sections) - 1
            inp.control_sections[idx].events.append(event)

    # No real close timestamp after a crash: the last sample is the best proxy.
    inp.end_time_ms = max(last_ts, inp.start_time_ms)
    return inp, last_ts


def _remove(path: str) -> None:
    try:
        os.remove(path)
    except OSError:
        pass


def scan_for_orphaned_sessions() -> None:
    directory = report_paths.partial_directory()
    try:
        names = [n for n in os.listdir(directory)
                 if n.lower().endswith(".ndjson") and os.path.isfile(os.path.join(directory, n))]
    except OSError:
        names = []
    names.sort(key=str.lower)  # QDir defaults: case-insensitive filter, Name | IgnoreCase sort

    for name in names:
        file_path = directory + "/" + name
        inp, _last = parse_orphaned_file(file_path)

        if not inp.camera_name:
            tslog.log_critical(0, "orphaned diagnostics file had no usable header, discarding: " + file_path)
            _remove(file_path)
            continue

        report_file_name = report_generator.generate(inp)
        if not report_file_name:
            tslog.log_critical(0, "failed to render recovered report for: " + file_path)
            continue

        tslog.log_critical(0, "recovered orphaned diagnostics session, camera=" + inp.camera_name
                           + " report=" + report_file_name + " file=" + file_path)
        _remove(file_path)
