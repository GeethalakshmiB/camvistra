"""e-CAM212_USB UVC-extension controller.

Port of CamVistra/Model/src/E-cam212_USB_UVCExt_Model.cpp and
CamVistra/Controller/src/E-cam212_UVCExt_Controller.cpp.
QML: context property ``ecam212usbUvcextController`` (no QML type).

Unlike the See3CAM controllers this camera talks to the UVC extension unit
(``UvcExt::initialize(fd)`` on Linux, ``initUVCExtension(path)`` on Windows)
rather than a HID node.
"""

from __future__ import annotations

from PyQt5.QtCore import pyqtSignal, pyqtSlot

from camvistra.cameras.base import IS_WINDOWS, CameraController
from camvistra.native import sdk


class Ecam212USB_UvcExt_Controller(CameraController):
    SDK_CLASS = sdk.Ecam212_USB

    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVer'])
    hdrModeReceived = pyqtSignal(int, arguments=['value'])
    aeModeReceived = pyqtSignal(int, arguments=['value'])
    expCompMaxReceived = pyqtSignal(int, int, int, arguments=['min', 'max', 'value'])
    expCompMinReceived = pyqtSignal(int, int, int, arguments=['min', 'max', 'value'])
    horizontalFlipReceived = pyqtSignal(int, arguments=['value'])
    verticalFlipReceived = pyqtSignal(int, arguments=['value'])
    # ------------------------------------------------------------------
    # Initialisation
    # ------------------------------------------------------------------

    # One SDK instance per camera path, so several e-CAM212s can be open at
    # once (see E-cam212_USB_UVCExt_Model.cpp). Controls act on the active one.
    _DEFAULT_PATH = "__default__"

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._instances: dict = {}
        self._active_path = ""

    def _active(self):
        return self._instances.get(self._active_path)

    def _initialize_instance(self, devicePath: str, fileDes: int) -> int:
        if not devicePath or fileDes < 0:
            return 0
        cam = self.SDK_CLASS()
        if not IS_WINDOWS and cam.initialize(fileDes) != 1:
            return 0
        self._instances[devicePath] = cam
        return 1

    # QML calls both initialize(fd) (legacy) and initialize(path, fd).
    @pyqtSlot(int, result=int)
    @pyqtSlot(str, int, result=int)
    def initialize(self, *args) -> int:
        if IS_WINDOWS:
            return 1 if len(args) == 1 else 0
        if len(args) == 2:
            return self._initialize_instance(str(args[0]), int(args[1]))
        if self._initialize_instance(self._DEFAULT_PATH, int(args[0])) != 1:
            return 0
        self._active_path = self._DEFAULT_PATH
        self.readFirmwareVersion()
        self.readExposureCompensationMin()
        self.readExposureCompensationMax()
        self.getAEMode()
        self.getHDR()
        self.getHorizontalFlip()
        self.getVerticalFlip()
        return 1

    @pyqtSlot(str, result=int)
    def setActiveDevicePath(self, devicePath: str) -> int:
        if not devicePath or devicePath not in self._instances:
            return 0
        self._active_path = devicePath
        return 1

    @pyqtSlot(str)
    def removeDevice(self, devicePath: str) -> None:
        self._instances.pop(devicePath, None)
        if self._active_path == devicePath:
            self._active_path = ""

    @pyqtSlot()
    def clearDevices(self) -> None:
        self._instances.clear()
        self._active_path = ""

    @pyqtSlot(str, result=int)
    def initUVCExtension(self, devicePath: str) -> int:
        if not IS_WINDOWS or not devicePath:
            return 0
        cam = self.SDK_CLASS()
        if not cam.initUVCExtension(devicePath):
            return 0
        self._instances[devicePath] = cam
        return 1

    # The C++ Controller has no initializeFromDevicePath/deinitExtensionUnit
    # (QML uses initUVCExtension); the inherited slots would call SDK methods
    # this class lacks, so make them no-ops.
    @pyqtSlot(str, result=int)
    def initializeFromDevicePath(self, devicePath: str) -> int:
        return 0

    @pyqtSlot()
    def deinitExtensionUnit(self) -> None:
        pass

    # ------------------------------------------------------------------
    def _set_int(self, ok, success: str, failure: str) -> int:
        self.statusChanged.emit(success if ok else failure)
        return 1 if ok else 0

    @pyqtSlot(result=int)
    def resetDevice(self) -> int:
        cam = self._active()
        return self._set_int(cam is not None and cam.resetDevice(), "Device reset successfully", "Device reset failed")

    @pyqtSlot(result=int)
    def readFirmwareVersion(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, version = cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        return 0

    @pyqtSlot(result=int)
    def readSerialNumber(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, serial = cam.readSerialNumber()
        if ok:
            self.serialNumberReceived.emit(serial)
            return 1
        return 0

    @pyqtSlot(result=int)
    def readExposureCompensationMin(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, prop = cam.readExposureCompensationMin()
        if ok:
            self.expCompMinReceived.emit(int(prop["min"]), int(prop["max"]), int(prop["cur"]))
            return 1
        return 0

    @pyqtSlot(result=int)
    def readExposureCompensationMax(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, prop = cam.readExposureCompensationMax()
        if ok:
            self.expCompMaxReceived.emit(int(prop["min"]), int(prop["max"]), int(prop["cur"]))
            return 1
        return 0

    @pyqtSlot(result=int)
    def getAEMode(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, value = cam.getAEMode()
        if ok:
            self.aeModeReceived.emit(int(value))
            return 1
        return 0

    @pyqtSlot(result=int)
    def getHDR(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, value = cam.getHDR()
        if ok:
            self.hdrModeReceived.emit(int(bool(value)))
            return 1
        return 0

    @pyqtSlot(bool, result=int)
    def setHDR(self, value: bool) -> int:
        cam = self._active()
        return self._set_int(cam is not None and cam.setHDR(bool(value)),
                             "HDR Mode set successfully", "Set HDR mode failed")

    @pyqtSlot(int, result=int)
    def setAEMode(self, value: int) -> int:
        cam = self._active()
        return self._set_int(cam is not None and cam.setAEMode(value),
                             "Auto Exposure Control Mode set successfully", "Set AE mode failed")

    @pyqtSlot(int, result=int)
    def setExposureCompMin(self, value: int) -> int:
        cam = self._active()
        return self._set_int(cam is not None and cam.writeExposureCompensationMin(value),
                             "Minimum Exposure Compensation updated successfully",
                             "Update Minimum Exposure Compensation failed")

    @pyqtSlot(int, result=int)
    def setExposureCompMax(self, value: int) -> int:
        cam = self._active()
        return self._set_int(cam is not None and cam.writeExposureCompensationMax(value),
                             "Maximum Exposure Compensation updated successfully",
                             "Update Maximum Exposure Compensation failed")

    @pyqtSlot(result=int)
    def getHorizontalFlip(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, value = cam.readHorizontalFlip()
        if ok:
            self.horizontalFlipReceived.emit(int(bool(value)))
            return 1
        return 0

    @pyqtSlot(bool, result=int)
    def setHorizontalFlip(self, value: bool) -> int:
        cam = self._active()
        if cam is not None and cam.writeHorizontalFlip(bool(value)):
            self.horizontalFlipReceived.emit(int(bool(value)))
            self.statusChanged.emit("Horizontal Flip set successfully")
            return 1
        self.statusChanged.emit("Set Horizontal Flip failed")
        return 0

    @pyqtSlot(result=int)
    def getVerticalFlip(self) -> int:
        cam = self._active()
        if cam is None:
            return 0
        ok, value = cam.readVerticalFlip()
        if ok:
            self.verticalFlipReceived.emit(int(bool(value)))
            return 1
        return 0

    @pyqtSlot(bool, result=int)
    def setVerticalFlip(self, value: bool) -> int:
        cam = self._active()
        if cam is not None and cam.writeVerticalFlip(bool(value)):
            self.verticalFlipReceived.emit(int(bool(value)))
            self.statusChanged.emit("Vertical Flip set successfully")
            return 1
        self.statusChanged.emit("Set Vertical Flip failed")
        return 0
