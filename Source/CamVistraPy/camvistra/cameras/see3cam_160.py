"""See3CAM_160 controller.

Port of CamVistra/Model/src/See3CAM_160_Model.cpp and
CamVistra/Controller/src/See3CAM_160_Controller.cpp.
QML: context property ``see3cam160Controller``, type ``See3CAM160``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_160_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_160

    class autoFocusModes(enum.IntEnum):
        AF_CONTINUOUS = 0x06
        AF_ONESHOT = 0x01
    Q_ENUM(autoFocusModes)

    class awbPresetMode(enum.IntEnum):
        AWB_PRESET_CLOUDY = 0x01
        AWB_PRESET_DAYLIGHT = 0x02
        AWB_PRESET_FLASH = 0x03
        AWB_PRESET_COOLWHITE_FLOURECENT = 0x04
        AWB_PRESET_TUNGSTEN = 0x05
        AWB_PRESET_CANDLELIGHT = 0x06
        AWB_PRESET_HORIZON = 0x07
        AWB_PRESET_CUSTOM = 0x08
        AWB_PRESET_AUTO = 0x09
    Q_ENUM(awbPresetMode)

    class awbLockStatus(enum.IntEnum):
        AWB_LOCK_OFF = 0x00
        AWB_LOCK_ON = 0x01
    Q_ENUM(awbLockStatus)

    class aeMeteringMode(enum.IntEnum):
        AE_OFF = 0x00
        AE_CENTER_WEIGHTED_AVG = 0x01
        AE_ALL_BLOCK_INTEGRAL = 0x02
        AE_SMALL_AREA = 0x05
        AE_LARGE_AREA = 0x06
    Q_ENUM(aeMeteringMode)

    class aeLockStatus(enum.IntEnum):
        AE_LOCK_OFF = 0x00
        AE_LOCK_ON = 0x01
    Q_ENUM(aeLockStatus)

    class camFlickerMode(enum.IntEnum):
        FLICKER_AUTO_DETECTION = 0x00
        FLICKER_50HZ = 0x01
        FLICKER_60HZ = 0x02
        FLICKER_OFF = 0x04
    Q_ENUM(camFlickerMode)

    class cafScanRangeMode(enum.IntEnum):
        CAF_MACRO_RANGE_MODE = 0x00
        CAF_NORMAL_RANGE_MODE = 0x01
        CAF_FULL_RANGE_MODE = 0x02
        CAF_INFINITY_RANGE_MODE = 0x03
        CAF_HYPERFOCAL_RANGE_MODE = 0x04
    Q_ENUM(cafScanRangeMode)

    class afLockStatus(enum.IntEnum):
        AF_LOCK_OFF = 0x00
        AF_LOCK_ON = 0x01
    Q_ENUM(afLockStatus)

    class manualLensPositionMode(enum.IntEnum):
        LENS_POS_INF = 0x01
        LENS_POS_NORMAL = 0x02
        LENS_BARCODE_POS = 0x03
        LENS_MACRO_POS = 0x04
        LENS_INITIAL_DAC_POS = 0x05
        LENS_CUSTOM_POS = 0x06
    Q_ENUM(manualLensPositionMode)

    class afStatus(enum.IntEnum):
        AF_ON = 0x00
        AF_OFF = 0x06
    Q_ENUM(afStatus)

    class autoFocusROIMode(enum.IntEnum):
        ROI_CENTERED = 0x00
        ROI_CUSTOM = 0x01
    Q_ENUM(autoFocusROIMode)

    afModeChanged = pyqtSignal("uint", arguments=['afMode'])
    qFactorValue = pyqtSignal("uint", arguments=['qFactor'])
    flickerModeChanged = pyqtSignal("uint", arguments=['flickerMode'])
    awbPresetModeChanged = pyqtSignal("uint", arguments=['awbMode'])
    awbLockStatusChanged = pyqtSignal("uint", arguments=['lockStatus'])
    aeLockStatusChanged = pyqtSignal("uint", arguments=['lockStatus'])
    aeMeterModeChanged = pyqtSignal("uint", arguments=['meterMode'])
    afStatusChanged = pyqtSignal("uint", arguments=['afstatus'])
    manualLensPositionModeChanged = pyqtSignal("uint", arguments=['lensPosMode'])
    afLockStatusChanged = pyqtSignal("uint", arguments=['lockStatus'])
    autoFocusRoiModeChanged = pyqtSignal("uint", arguments=['afRoiMode'])
    cafScanRangeModeChanged = pyqtSignal("uint", arguments=['scanRangeMode'])
    burstLengthValue = pyqtSignal("uint", arguments=['burstLength'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_value(self, getter, signal) -> bool:
        ok, value = getter()
        if ok:
            signal.emit(value)
            return True
        return False

    # ---- Auto Focus Mode ---------------------------------------------

    @pyqtSlot(result=bool)
    def getAutoFocusMode(self) -> bool:
        return self._get_value(self._cam.getAFMode, self.afModeChanged)

    @pyqtSlot(int, result=bool)
    def setAutoFocusMode(self, afMode: int) -> bool:
        return self._set(self._cam.setAFMode(afMode & 0xFF),
                         "Auto focus mode set successfully", "Set auto focus mode failed")

    # ---- Q Factor ----------------------------------------------------

    @pyqtSlot(result=bool)
    def getQFactor(self) -> bool:
        return self._get_value(self._cam.getQFactor, self.qFactorValue)

    @pyqtSlot("uint", result=bool)
    def setQFactor(self, qFactor: int) -> bool:
        return self._set(self._cam.setQFactor(qFactor & 0xFF),
                         "Q factor set successfully", "Set Q factor failed")

    # ---- Default / Firmware ------------------------------------------

    @pyqtSlot(result=bool)
    def setToDefault(self) -> bool:
        return self._set(self._cam.restoreDefault(),
                         "Device reset to defaults successfully", "Reset to defaults failed")

    @pyqtSlot(result=bool)
    def getFirmwareVersion(self) -> bool:
        ok, v = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(f"{v['byte1']}.{v['byte2']}.{v['byte3']}")
            return True
        return False

    # ---- Flicker -----------------------------------------------------

    @pyqtSlot(result=bool)
    def getFlickerMode(self) -> bool:
        return self._get_value(self._cam.getFlickerMode, self.flickerModeChanged)

    @pyqtSlot(int, result=bool)
    def setFlickerMode(self, flickerMode: int) -> bool:
        return self._set(self._cam.setFlickerMode(flickerMode & 0xFF),
                         "Flicker mode set successfully", "Set flicker mode failed")

    # ---- AWB Lock / Preset -------------------------------------------

    @pyqtSlot(result=bool)
    def getAWBlockstatus(self) -> bool:
        return self._get_value(self._cam.getAWBLockStatus, self.awbLockStatusChanged)

    @pyqtSlot(int, result=bool)
    def setAWBlockstatus(self, lockStatus: int) -> bool:
        return self._set(self._cam.setAWBLockStatus(lockStatus & 0xFF),
                         "AWB lock status set successfully", "Set AWB lock status failed")

    @pyqtSlot(result=bool)
    def getAWBpresetMode(self) -> bool:
        return self._get_value(self._cam.getAWBPresetMode, self.awbPresetModeChanged)

    @pyqtSlot(int, result=bool)
    def setAWBpresetMode(self, awbMode: int) -> bool:
        return self._set(self._cam.setAWBPresetMode(awbMode & 0xFF),
                         "AWB preset mode set successfully", "Set AWB preset mode failed")

    # ---- AE Lock / Metering ------------------------------------------

    @pyqtSlot(result=bool)
    def getAElockstatus(self) -> bool:
        return self._get_value(self._cam.getAELockStatus, self.aeLockStatusChanged)

    @pyqtSlot(int, result=bool)
    def setAElockstatus(self, lockStatus: int) -> bool:
        return self._set(self._cam.setAELockStatus(lockStatus & 0xFF),
                         "AE lock status set successfully", "Set AE lock status failed")

    @pyqtSlot(result=bool)
    def getAEMeterMode(self) -> bool:
        return self._get_value(self._cam.getAEMeteringMode, self.aeMeterModeChanged)

    @pyqtSlot(int, result=bool)
    def setAEMeterMode(self, meterMode: int) -> bool:
        return self._set(self._cam.setAEMeteringMode(meterMode & 0xFF),
                         "AE metering mode set successfully", "Set AE metering mode failed")

    # ---- AF Status / Lens Position / AF Lock -------------------------

    @pyqtSlot(result=bool)
    def getAFstatus(self) -> bool:
        return self._get_value(self._cam.getAFStatus, self.afStatusChanged)

    @pyqtSlot(int, result=bool)
    def setAFstatus(self, afstatus: int) -> bool:
        return self._set(self._cam.setAFStatus(afstatus & 0xFF),
                         "AF status set successfully", "Set AF status failed")

    @pyqtSlot(result=bool)
    def getManualLensPositionMode(self) -> bool:
        return self._get_value(self._cam.getManualLensPosition, self.manualLensPositionModeChanged)

    @pyqtSlot(int, result=bool)
    def setManualLensPositionMode(self, lensPosition: int) -> bool:
        return self._set(self._cam.setManualLensPosition(lensPosition & 0xFF),
                         "Manual lens position set successfully", "Set manual lens position failed")

    @pyqtSlot(result=bool)
    def getAFlockstatus(self) -> bool:
        return self._get_value(self._cam.getAFLockStatus, self.afLockStatusChanged)

    @pyqtSlot(int, result=bool)
    def setAFlockstatus(self, lockStatus: int) -> bool:
        return self._set(self._cam.setAFLockStatus(lockStatus & 0xFF),
                         "AF lock status set successfully", "Set AF lock status failed")

    # ---- CAF Scan Range ----------------------------------------------

    @pyqtSlot(result=bool)
    def getCAFScanRangeMode(self) -> bool:
        return self._get_value(self._cam.getCAFScanRange, self.cafScanRangeModeChanged)

    @pyqtSlot(int, result=bool)
    def setCAFScanRangeMode(self, cafMode: int) -> bool:
        return self._set(self._cam.setCAFScanRange(cafMode & 0xFF),
                         "CAF scan range mode set successfully", "Set CAF scan range mode failed")

    # ---- AF ROI --------------------------------------------------------

    @pyqtSlot(result=bool)
    def getAutoFocusROIMode(self) -> bool:
        return self._get_value(self._cam.getAFROIMode, self.autoFocusRoiModeChanged)

    @pyqtSlot(result=bool)
    def setCenteredAutoFocusMode(self) -> bool:
        return self._set(self._cam.setAFROICenteredMode(),
                         "Centered auto focus mode set successfully", "Set centered auto focus mode failed")

    @pyqtSlot(int, int, "uint", "uint", result=bool)
    def setCustomAreaAutoFocus(self, vidResolnWidth: int, vidResolnHeight: int, xCord: int, yCord: int) -> bool:
        # The window is (xMin, xMax, yMin, yMax) = (x, x + width, y, y + height);
        # the width/height arguments are the window size despite their C++ names.
        return self._set(
            self._cam.setAFROICustomMode(xCord & 0xFFFF, (xCord + vidResolnWidth) & 0xFFFF,
                                         yCord & 0xFFFF, (yCord + vidResolnHeight) & 0xFFFF),
            "Custom area auto focus set successfully", "Set custom area auto focus failed")

    # ---- Burst Length ------------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setBurstLength(self, burstLength: int) -> bool:
        return self._set(self._cam.setBurstLength(burstLength & 0xFF),
                         "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=bool)
    def getBurstLength(self) -> bool:
        return self._get_value(self._cam.getBurstLength, self.burstLengthValue)

    # ---- Serial Number -----------------------------------------------

    @pyqtSlot(result=bool)
    def get64BitSerialNumber(self) -> bool:
        return self._get_value(self._cam.getUniqueID64, self.serialNumberReceived)
