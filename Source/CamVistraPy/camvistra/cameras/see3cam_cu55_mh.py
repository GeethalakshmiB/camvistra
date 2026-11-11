"""See3CAM_CU55_MH controller.

Port of CamVistra/Model/src/See3CAM_CU55_MH_Model.cpp and
CamVistra/Controller/src/See3CAM_CU55_MH_Controller.cpp.
QML: context property ``see3camcu55mhController``, type ``See3CAMCU55MH``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import IS_WINDOWS, CameraController
from camvistra.native import sdk


class See3CAM_CU55_MH_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU55_MH

    class StreamModeCU55_MH(enum.IntEnum):
        STREAM_MODE_MASTER = 0x00
        STREAM_MODE_TRIGGER = 0x01
    Q_ENUM(StreamModeCU55_MH)

    class FlashModeCU55_MH(enum.IntEnum):
        FLASH_MODE_OFF = 0x00
        FLASH_MODE_STROBE = 0x01
        FLASH_MODE_TORCH = 0x02
    Q_ENUM(FlashModeCU55_MH)

    class FlipModeCU55_MH(enum.IntEnum):
        FLIP_MODE_NORMAL = 0x00
        FLIP_MODE_HORIZONTAL = 0x01
        FLIP_MODE_VERTICAL = 0x02
        FLIP_MODE_BOTH = 0x03
    Q_ENUM(FlipModeCU55_MH)

    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
    orientationReceived = pyqtSignal(int, arguments=['flipMode'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ---- Initialisation (differs from the base: reports status) --------

    @pyqtSlot(int, result=int)
    def initialize(self, fileDes: int) -> int:
        self._fd = fileDes
        if not self._cam.setHidFd(fileDes):
            self.statusChanged.emit("CU55MH HID init failed")
            return 0
        self.statusChanged.emit("CU55MH HID initialized")
        return 1

    @pyqtSlot(str, result=int)
    def initializeFromDevicePath(self, devicePath: str) -> int:
        if not IS_WINDOWS:
            return 0
        self._fd = -1
        if not self._cam.initFromDevicePath(devicePath):
            self.statusChanged.emit("CU55MH device init failed")
            return 0
        self.statusChanged.emit("CU55MH device initialized")
        return 1

    @pyqtSlot()
    def deinitExtensionUnit(self) -> None:
        self._fd = -1
        if IS_WINDOWS:
            self._cam.deinitExtensionUnit()

    # ---- Stream Mode -----------------------------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        ok, streamMode = self._cam.getStreamMode()
        if not ok:
            self.statusChanged.emit("CU55MH get stream mode failed")
            return -1
        self.streamModeReceived.emit(int(streamMode))
        return int(streamMode)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, streamMode: int) -> int:
        if not self._cam.setStreamMode(streamMode):
            self.statusChanged.emit("CU55MH set stream mode failed")
            return 0
        self.streamModeReceived.emit(streamMode)
        return 1

    # ---- Flash Mode ------------------------------------------------------

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        ok, flashMode = self._cam.getFlashMode()
        if not ok:
            self.statusChanged.emit("CU55MH get flash mode failed")
            return -1
        self.flashModeReceived.emit(int(flashMode))
        return int(flashMode)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        if not self._cam.setFlashMode(flashMode):
            self.statusChanged.emit("CU55MH set flash mode failed")
            return 0
        self.flashModeReceived.emit(flashMode)
        return 1

    # ---- Orientation -----------------------------------------------------

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        ok, flipMode = self._cam.getOrientation()
        if not ok:
            self.statusChanged.emit("CU55MH get orientation failed")
            return -1
        self.orientationReceived.emit(int(flipMode))
        return int(flipMode)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, horzFlip: bool, vertFlip: bool) -> int:
        if not self._cam.setOrientation(horzFlip, vertFlip):
            self.statusChanged.emit("CU55MH set orientation failed")
            return 0
        flipMode = 0
        if horzFlip and vertFlip:
            flipMode = 0x03
        elif horzFlip:
            flipMode = 0x01
        elif vertFlip:
            flipMode = 0x02
        self.orientationReceived.emit(flipMode)
        return 1

    # ---- Default / Serial / Firmware -------------------------------------

    @pyqtSlot(result=int)
    def restoreDefault(self) -> int:
        if not self._cam.restoreDefault():
            self.statusChanged.emit("CU55MH restore default failed")
            return 0
        self.statusChanged.emit("CU55MH restored to defaults")
        return 1

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, serial = self._cam.get64BitSerialNumber()
        if not ok:
            self.statusChanged.emit("CU55MH serial read failed")
            return 0
        # QString::number(uint64_t) - decimal
        self.serialNumberReceived.emit(str(int(serial) & 0xFFFFFFFFFFFFFFFF))
        return 1

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, version = self._cam.readFirmwareVersion()
        if not ok:
            self.statusChanged.emit("CU55MH firmware read failed")
            return 0
        self.firmwareVersionReceived.emit(version)
        return 1
