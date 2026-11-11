"""Device-control-change notification interface (port of IUvcControlProvider.h).

Unlike ISystemMetricsProvider this needs no per-OS implementation: CAMSDK's
Get/SetCameraControlProperty already hides V4L2 vs. DirectShow/MF, and
Routecam's SDK exposes the same pair. So there are three thin adapters, one
per SDK shape:

* CamsdkUvcControlAdapter   (USB/See3CAM family, via UsbCameraModel)
* RoutecamUvcControlAdapter (Routecam family, via RoutecamOnvifController)
* WifiOnvifControlAdapter   (WifiOnvif family - named setters)

Each adapter exposes ``report_*`` methods that the corresponding model/
controller calls after a successful set; all of them emit the same
``controlChanged(name, value, timestampMs)`` signal, so DiagnosticSession
never needs to know which SDK an event came from. The signal keeps the
C++ camelCase name (Qt signal convention used across CamVistra).
"""

from __future__ import annotations

from PyQt5.QtCore import QObject, pyqtSignal

from camvistra.diagnostics.diagnostics_data import now_ms


class IUvcControlProvider(QObject):
    # (controlName, value, timestampMs); qint64 because epoch-ms overflows int.
    controlChanged = pyqtSignal(str, int, "qint64")

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)

    def _emit(self, control_name: str, value) -> None:
        self.controlChanged.emit(str(control_name), int(value), now_ms())
