"""Runtime diagnostics (port of CamVistra/Diagnostics).

Per-camera sessions sample FPS/CPU/memory/latency and device-control
changes, mirror them to a crash-recovery NDJSON trail and render a PDF
report on close (``<Documents>/CamVistra/Reports``).

Application wiring (main.cpp equivalent):

* after QApplication is created and before any camera opens:
  ``scan_for_orphaned_sessions()``
* after ``app.exec_()`` returns, before QApplication is destroyed:
  ``DiagnosticsManager.instance().shutdown()``

The C++ ``qRegisterMetaType<FpsSample/...>`` calls have no PyQt equivalent
and are not needed (the samples travel as ``pyqtSignal(object)``).
"""

from __future__ import annotations

# Every PyQt5 module used here must be loaded before camvistra.native (via
# camvistra.tslog) registers the SDK directory, which also holds the C++
# build's Qt 5.14 DLLs - otherwise QtGui/QtChart bind to the wrong Qt.
import PyQt5.QtCore  # noqa: F401,E402
import PyQt5.QtGui  # noqa: F401,E402
import PyQt5.QtWidgets  # noqa: F401,E402
import PyQt5.QtChart  # noqa: F401,E402

from camvistra.diagnostics.camsdk_uvc_control_adapter import CamsdkUvcControlAdapter
from camvistra.diagnostics.crash_recovery_scanner import scan_for_orphaned_sessions
from camvistra.diagnostics.diagnostic_session import DiagnosticSession
from camvistra.diagnostics.diagnostics_data import ControlEvent, FpsSample, LatencySample, ResourceSample
from camvistra.diagnostics.diagnostics_manager import DiagnosticsManager
from camvistra.diagnostics.i_system_metrics_provider import ISystemMetricsProvider
from camvistra.diagnostics.metrics_collector import MetricsCollector
from camvistra.diagnostics.report_paths import partial_directory, reports_directory
from camvistra.diagnostics.routecam_uvc_control_adapter import RoutecamUvcControlAdapter
from camvistra.diagnostics.system_metrics_provider import SystemMetricsProvider
from camvistra.diagnostics.uvc_control_provider import IUvcControlProvider
from camvistra.diagnostics.wifi_onvif_control_adapter import WifiOnvifControlAdapter

__all__ = [
    "CamsdkUvcControlAdapter", "ControlEvent", "DiagnosticSession", "DiagnosticsManager", "FpsSample",
    "ISystemMetricsProvider", "IUvcControlProvider", "LatencySample", "MetricsCollector", "ResourceSample",
    "RoutecamUvcControlAdapter", "SystemMetricsProvider", "WifiOnvifControlAdapter", "partial_directory",
    "reports_directory", "scan_for_orphaned_sessions",
]
