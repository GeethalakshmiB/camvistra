"""See3CAM_CU512M controller.

Port of CamVistra/Model/src/See3CAM_CU512M_Model.cpp and
CamVistra/Controller/src/See3CAM_CU512M_Controller.cpp.
QML: context property ``see3camcu512mController``, type ``See3CAMCU512M``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU512M_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU512M

    class StreamModeCU512M(enum.IntEnum):
        MASTER = 0x01
        TRIGGER = 0x02
    Q_ENUM(StreamModeCU512M)

    class FlashModeCU512M(enum.IntEnum):
        DISABLE = 0x00
        STROBE = 0x01
        TORCH = 0x02
    Q_ENUM(FlashModeCU512M)

    class FlipModeCU512M(enum.IntEnum):
        NORMAL = 0x00
        HORIZONTAL = 0x01
        VERTICAL = 0x02
        ROTATE_180 = 0x03
    Q_ENUM(FlipModeCU512M)

    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
    orientationReceived = pyqtSignal(int, arguments=['flipMode'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_value(self, getter, signal) -> int:
        ok, value = getter()
        if ok:
            signal.emit(int(value))
            return 1
        return 0

    def _set_int(self, ok, success: str, failure: str) -> int:
        self.statusChanged.emit(success if ok else failure)
        return 1 if ok else 0

    # ---- Stream Mode -----------------------------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get_value(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, streamMode: int) -> int:
        return self._set_int(self._cam.setStreamMode(streamMode),
                             "Stream mode set successfully", "Set stream mode failed")

    # ---- Flash Mode ------------------------------------------------------

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get_value(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        return self._set_int(self._cam.setFlashMode(flashMode),
                             "Flash mode set successfully", "Set flash mode failed")

    # ---- Orientation / Flip ----------------------------------------------

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get_value(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setOrientation(horzFlip, vertFlip),
                             "Orientation set successfully", "Set orientation failed")

    # ---- Factory Restore -------------------------------------------------

    @pyqtSlot(result=int)
    def restoreDefault(self) -> int:
        return self._set_int(self._cam.restoreDefault(),
                             "Device reset to defaults successfully", "Reset to defaults failed")

    # ---- Serial / Firmware -----------------------------------------------

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
