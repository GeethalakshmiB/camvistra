"""E-cam16_USB controller.

Port of CamVistra/Model/src/E-cam16_USB_Model.cpp and
CamVistra/Controller/src/E-cam16_USB_Controller.cpp.
QML: context property ``ecam16usbController`` (no QML type registered).

Unlike the See3CAM controllers, the C++ Controller takes a *device path*
in ``initialize`` (Linux: the /dev/videoN path handed to the SDK) and opens
the Windows extension unit via ``initUVCExtension``.
"""

from __future__ import annotations

from PyQt5.QtCore import pyqtSignal, pyqtSlot

from camvistra.cameras.base import IS_WINDOWS, CameraController
from camvistra.native import sdk


class ECAM16USB_Controller(CameraController):
    SDK_CLASS = sdk.Ecam16_USB

    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVer'])
    # ------------------------------------------------------------------
    # Initialisation
    # ------------------------------------------------------------------

    @pyqtSlot(str, result=int)
    def initialize(self, devicePath: str) -> int:
        if not IS_WINDOWS:
            self._cam.initialize(devicePath)
        return 1

    @pyqtSlot(str, result=int)
    def initUVCExtension(self, devicePath: str) -> int:
        if IS_WINDOWS:
            return 1 if self._cam.initUVCExtension(devicePath) else 0
        return 0  # Linux: the C++ Controller only logs the path

    # The C++ Controller has no initializeFromDevicePath/deinitExtensionUnit and
    # the SDK class has no initFromDevicePath/deinitExtensionUnit; override the
    # inherited base slots so they cannot raise AttributeError.
    @pyqtSlot(str, result=int)
    def initializeFromDevicePath(self, devicePath: str) -> int:
        return 0

    @pyqtSlot()
    def deinitExtensionUnit(self) -> None:
        pass

    # ------------------------------------------------------------------

    @pyqtSlot(result=int)
    def readFirmwareVersion(self) -> int:
        ok, version = self._unpack(self._cam.readFirmwareVersion())
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        return 0
