"""e-CAM82_USB controller.

Port of CamVistra/Model/src/e-CAM82_USB_Model.cpp and
CamVistra/Controller/src/e-CAM82_USB_Controller.cpp.
QML: context property ``ecam82usbController`` (no QML type registered).

The SDK class (eCamSDK::Ecam82_USB) derives from UvcExt, which provides
``initialize(int fd)`` on Linux and ``initUVCExtension(const wchar_t*)`` on
Windows.
"""

from __future__ import annotations

from PyQt5.QtCore import pyqtSignal, pyqtSlot

from camvistra.cameras.base import IS_WINDOWS, CameraController
from camvistra.native import sdk


class ECAM82USB_Controller(CameraController):
    SDK_CLASS = sdk.Ecam82_USB

    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVer'])
    # ------------------------------------------------------------------
    # Initialisation
    # ------------------------------------------------------------------

    @pyqtSlot(int, result=int)
    def initialize(self, fileDes: int) -> int:
        if not IS_WINDOWS:
            self._fd = fileDes
            self._cam.initialize(self._fd)
        return 1

    @pyqtSlot(str, result=int)
    def initUVCExtension(self, devicePath: str) -> int:
        init = getattr(self._cam, "initUVCExtension", None)  # Windows-only binding
        if IS_WINDOWS and init is not None:
            return 1 if init(devicePath) else 0
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
