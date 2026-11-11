"""See3CAM_CU200M controller.

Port of CamVistra/Model/src/See3CAM_CU200M_Model.cpp and
CamVistra/Controller/src/See3CAM_CU200M_Controller.cpp.
QML: context property ``see3camcu200mController``, type ``See3CAMCU200M``.

initialize / initializeFromDevicePath / deinitExtensionUnit behave exactly
like the base class.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU200M_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU200M

    class StreamModeCU200M(enum.IntEnum):
        STREAM_MODE_MASTER = 0x01
        STREAM_MODE_TRIGGER = 0x02
    Q_ENUM(StreamModeCU200M)

    class FlashModeCU200M(enum.IntEnum):
        FLASH_MODE_DISABLE = 0x00
        FLASH_MODE_STROBE = 0x01
        FLASH_MODE_TORCH = 0x02
    Q_ENUM(FlashModeCU200M)

    class FlipModeCU200M(enum.IntEnum):
        FLIP_MODE_NORMAL = 0x00
        FLIP_MODE_HORIZONTAL = 0x01
        FLIP_MODE_VERTICAL = 0x02
        FLIP_MODE_ROTATE_180 = 0x03
    Q_ENUM(FlipModeCU200M)

    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
    orientationReceived = pyqtSignal(int, arguments=['flipMode'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get(self, getter, signal) -> int:
        ok, value = self._unpack(getter())
        if ok:
            signal.emit(int(value))
            return 1
        return 0

    def _set_int(self, ok, success: str, failure: str) -> int:
        return 1 if self._set(ok, success, failure) else 0

    # ---- Stream / Flash / Orientation ---------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, streamMode: int) -> int:
        return self._set_int(self._cam.setStreamMode(streamMode),
                             "Stream mode set successfully", "Set stream mode failed")

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        return self._set_int(self._cam.setFlashMode(flashMode),
                             "Flash mode set successfully", "Set flash mode failed")

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setOrientation(horzFlip, vertFlip),
                             "Orientation set successfully", "Set orientation failed")

    # ---- Default / Serial / Firmware ----------------------------------

    @pyqtSlot(result=int)
    def restoreDefault(self) -> int:
        return self._set_int(self._cam.restoreDefault(),
                             "Device reset to defaults successfully", "Reset to defaults failed")

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, serial = self._cam.getCameraUniqueID64()
        if ok:
            self.serialNumberReceived.emit(serial)
            return 1
        self.statusChanged.emit("Read serial number failed")
        return 0

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, version = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        self.statusChanged.emit("Read firmware version failed")
        return 0
