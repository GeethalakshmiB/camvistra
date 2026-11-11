"""See3CAM_CU27 controller.

Port of CamVistra/Model/src/See3CAM_CU27_Model.cpp and
CamVistra/Controller/src/See3CAM_CU27_Controller.cpp.
QML: context property ``see3camcu27Controller``, type ``See3CAMCU27``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU27_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU27

    class AWBPresetModeCU27(enum.IntEnum):
        AWB_PRESET_CLOUDY = 0x01
        AWB_PRESET_DAYLIGHT = 0x02
        AWB_PRESET_FLASH = 0x03
        AWB_PRESET_COOLWHITE_FLUOR = 0x04
        AWB_PRESET_TUNGSTEN = 0x05
        AWB_PRESET_CANDLELIGHT = 0x06
        AWB_PRESET_HORIZON = 0x07
        AWB_PRESET_CUSTOM = 0x08
        AWB_PRESET_AUTO = 0x09
    Q_ENUM(AWBPresetModeCU27)

    class AWBLockStatusCU27(enum.IntEnum):
        AWB_LOCK_OFF = 0x00
        AWB_LOCK_ON = 0x01
    Q_ENUM(AWBLockStatusCU27)

    class AEMeteringModeCU27(enum.IntEnum):
        AE_OFF = 0x00
        AE_CENTER_WEIGHTED_AVG = 0x01
        AE_ALL_BLOCK_INTEGRAL = 0x02
        AE_SMALL_AREA = 0x05
        AE_LARGE_AREA = 0x06
    Q_ENUM(AEMeteringModeCU27)

    class AELockStatusCU27(enum.IntEnum):
        AE_LOCK_OFF = 0x00
        AE_LOCK_ON = 0x01
    Q_ENUM(AELockStatusCU27)

    class FlickerModeCU27(enum.IntEnum):
        FLICKER_AUTO = 0x00
        FLICKER_50HZ = 0x01
        FLICKER_60HZ = 0x02
        FLICKER_OFF = 0x04
    Q_ENUM(FlickerModeCU27)

    class DenoiseModesCU27(enum.IntEnum):
        DENOISE_DISABLE = 0x00
        DENOISE_ENABLE = 0x01
    Q_ENUM(DenoiseModesCU27)

    # AWB / AE
    awbPresetModeReceived = pyqtSignal(int, arguments=['awbMode'])
    awbLockStatusReceived = pyqtSignal(int, arguments=['lockStatus'])
    aeMeteringModeReceived = pyqtSignal(int, arguments=['meterMode'])
    aeLockStatusReceived = pyqtSignal(int, arguments=['lockStatus'])
    # Flicker / JPEG / Burst
    flickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    # Denoise / Roll
    denoiseModeReceived = pyqtSignal(int, arguments=['denoiseMode'])
    rollValueReceived = pyqtSignal(int, arguments=['rollValue'])
    # Firmware / Serial
    ispFirmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_u8(self, getter, signal) -> int:
        ok, value = getter()
        if ok:
            signal.emit(int(value))
            return 1
        return 0

    def _set_int(self, ok, success: str, failure: str) -> int:
        return 1 if self._set(ok, success, failure) else 0

    # ---- AWB ------------------------------------------------------------

    @pyqtSlot(result=int)
    def getAWBPresetMode(self) -> int:
        return self._get_u8(self._cam.getAWBPresetMode, self.awbPresetModeReceived)

    @pyqtSlot(int, result=int)
    def setAWBPresetMode(self, awbMode: int) -> int:
        return self._set_int(self._cam.setAWBPresetMode(awbMode),
                             "AWB preset mode set successfully", "Set AWB preset mode failed")

    @pyqtSlot(result=int)
    def getAWBLockStatus(self) -> int:
        return self._get_u8(self._cam.getAWBLockStatus, self.awbLockStatusReceived)

    @pyqtSlot(int, result=int)
    def setAWBLockStatus(self, lockStatus: int) -> int:
        return self._set_int(self._cam.setAWBLockStatus(lockStatus),
                             "AWB lock status set successfully", "Set AWB lock status failed")

    # ---- AE ---------------------------------------------------------------

    @pyqtSlot(result=int)
    def getAEMeteringMode(self) -> int:
        return self._get_u8(self._cam.getAEMeteringMode, self.aeMeteringModeReceived)

    @pyqtSlot(int, result=int)
    def setAEMeteringMode(self, meterMode: int) -> int:
        return self._set_int(self._cam.setAEMeteringMode(meterMode),
                             "AE metering mode set successfully", "Set AE metering mode failed")

    @pyqtSlot(result=int)
    def getAELockStatus(self) -> int:
        return self._get_u8(self._cam.getAELockStatus, self.aeLockStatusReceived)

    @pyqtSlot(int, result=int)
    def setAELockStatus(self, lockStatus: int) -> int:
        return self._set_int(self._cam.setAELockStatus(lockStatus),
                             "AE lock status set successfully", "Set AE lock status failed")

    # ---- Flicker / Q-factor / Burst ----------------------------------------

    @pyqtSlot(result=int)
    def getFlickerMode(self) -> int:
        return self._get_u8(self._cam.getFlickerMode, self.flickerModeReceived)

    @pyqtSlot(int, result=int)
    def setFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setFlickerMode(flickerMode),
                             "Flicker mode set successfully", "Set flicker mode failed")

    @pyqtSlot(result=int)
    def getQFactor(self) -> int:
        return self._get_u8(self._cam.getQFactor, self.qFactorReceived)

    @pyqtSlot(int, result=int)
    def setQFactor(self, qFactor: int) -> int:
        return self._set_int(self._cam.setQFactor(qFactor & 0xFF),
                             "Q factor set successfully", "Set Q factor failed")

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_u8(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    # ---- Denoise / Roll ------------------------------------------------------

    @pyqtSlot(result=int)
    def getDenoiseMode(self) -> int:
        return self._get_u8(self._cam.getDenoiseMode, self.denoiseModeReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseMode(self, denoiseMode: int) -> int:
        return self._set_int(self._cam.setDenoiseMode(denoiseMode),
                             "Denoise mode set successfully", "Set denoise mode failed")

    @pyqtSlot(result=int)
    def getRollValue(self) -> int:
        return self._get_u8(self._cam.getRollValue, self.rollValueReceived)

    @pyqtSlot(int, result=int)
    def setRollValue(self, rollValue: int) -> int:
        return self._set_int(self._cam.setRollValue(rollValue & 0xFF),
                             "Roll value set successfully", "Set roll value failed")

    # ---- Firmware / Default / Serial -----------------------------------------

    @pyqtSlot(result=int)
    def readISPFirmwareVersion(self) -> int:
        ok, v = self._cam.readISPFirmwareVersion()
        if ok:
            self.ispFirmwareVersionReceived.emit(
                "%d.%d.%d.%d" % (v["major"], v["minor1"], v["minor2"], v["minor3"]))
            return 1
        self.statusChanged.emit("Read ISP firmware version failed")
        return 0

    @pyqtSlot(result=int)
    def setToDefault(self) -> int:
        return self._set_int(self._cam.setToDefault(),
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
