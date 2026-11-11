"""See3CAM_CU135M_H01R1 controller.

Port of CamVistra/Model/src/See3CAM_CU135M_H01R1_Model.cpp and
CamVistra/Controller/src/See3CAM_CU135M_H01R1_Controller.cpp.
QML: context property ``see3camcu135mh01r1Controller``, type ``See3CAMCU135M_H01R1``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU135M_H01R1_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU135M_H01R1

    class flashStateValues(enum.IntEnum):
        FLASHMODE_OFF = 0x00
        FLASHMODE_TORCH = 0x02
        FLASHMODE_STROBE = 0x01
    Q_ENUM(flashStateValues)

    class streamModes(enum.IntEnum):
        MODE_MASTER = 0x00
        MODE_TRIGGER = 0x01
    Q_ENUM(streamModes)

    class flipControls(enum.IntEnum):
        FLIP_NORMAL = 0x00
        FLIP_HORIZONTAL = 0x01
        FLIP_VERTICAL = 0x02
        FLIP_BOTH = 0x03
    Q_ENUM(flipControls)

    class camROIAutoExpMode(enum.IntEnum):
        AE_Full = 0x01
        AE_Manual = 0x02
    Q_ENUM(camROIAutoExpMode)

    class blackLevelAdjustment(enum.IntEnum):
        ENABLE = 0x01
        DISABLE = 0x02
    Q_ENUM(blackLevelAdjustment)

    class gainMode(enum.IntEnum):
        AUTO_GAIN = 0x00
        MANUAL_GAIN = 0x01
    Q_ENUM(gainMode)

    class autoGain(enum.IntEnum):
        CONTINUOUS = 0x00
        SINGLE_SHOT = 0x01
    Q_ENUM(autoGain)

    class exposureModes(enum.IntEnum):
        CONTINUOUS_EXPOSURE = 0x00
        SINGLE_SHOT_EXPOSURE = 0x01
    Q_ENUM(exposureModes)

    class antiFlickerDetection(enum.IntEnum):
        MODE_50Hz = 0x00
        MODE_60Hz = 0x01
        MODE_DISABLE = 0x02
    Q_ENUM(antiFlickerDetection)

    flashModeReceived = pyqtSignal("uint", arguments=['flashMode'])
    streamModeReceived = pyqtSignal("uint", arguments=['streamMode'])
    flipModeReceived = pyqtSignal("uint", arguments=['flipValue'])
    roiAutoExpModeReceived = pyqtSignal("uint", "uint", arguments=['roiMode', 'winSize'])
    blackLevelAdjustmentReceived = pyqtSignal("uint", arguments=['blacklevel'])
    targetBrightnessReceived = pyqtSignal("uint", arguments=['brightness'])
    antiFlickerModeReceived = pyqtSignal("uint", arguments=['antiFlicker'])
    gainModeReceived = pyqtSignal("uint", "uint", "uint", arguments=['gainMode', 'autoGainMode', 'gainValue'])
    exposureModeReceived = pyqtSignal("uint", arguments=['exposureMode'])
    lowerLimitGainReceived = pyqtSignal("uint", arguments=['lowerLimit'])
    upperLimitGainReceived = pyqtSignal("uint", arguments=['upperLimit'])
    exposureLowerLimitReceived = pyqtSignal("uint", arguments=['lowerLimit'])
    exposureUpperLimitReceived = pyqtSignal("uint", arguments=['upperLimit'])
    statisticsReceived = pyqtSignal("uint", "uint", arguments=['exposureUs', 'gainValue'])
    crossStillPropertiesSet = pyqtSignal(bool, arguments=['success'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_value(self, getter, signal) -> bool:
        ok, value = getter()
        if ok:
            signal.emit(value)
            return True
        return False

    # ---- Flash ---------------------------------------------------------

    @pyqtSlot(int, result=bool)
    def setFlashState(self, flashMode: int) -> bool:
        return self._set(self._cam.setFlashMode(flashMode),
                         "Flash state set successfully", "Set flash state failed")

    @pyqtSlot(result=bool)
    def getFlashState(self) -> bool:
        return self._get_value(self._cam.getFlashMode, self.flashModeReceived)

    # ---- Stream Mode ---------------------------------------------------

    @pyqtSlot(result=bool)
    def getStreamMode(self) -> bool:
        return self._get_value(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=bool)
    def setStreamMode(self, streamMode: int) -> bool:
        return self._set(self._cam.setStreamMode(streamMode),
                         "Stream mode set successfully", "Set stream mode failed")

    # ---- Flip ----------------------------------------------------------

    @pyqtSlot(bool, bool, result=bool)
    def setFlipCtrlValue(self, horzModeSel: bool, vertiModeSel: bool) -> bool:
        return self._set(self._cam.setFlipMode(horzModeSel, vertiModeSel),
                         "Flip control set successfully", "Set flip control failed")

    @pyqtSlot(result=bool)
    def getFlipCtrlValue(self) -> bool:
        return self._get_value(self._cam.getFlipMode, self.flipModeReceived)

    # ---- ROI Auto Exposure -------------------------------------------

    @pyqtSlot(int, "uint", "uint", "uint", "uint", int, result=bool)
    def setROIAutoExposure(self, see3camAutoexpROIMode: int, vidResolnWidth: int, vidResolnHeight: int,
                           xCord: int, yCord: int, winSize: int) -> bool:
        return self._set(
            self._cam.setAutoExpROIMode(see3camAutoexpROIMode, vidResolnWidth, vidResolnHeight,
                                        xCord, yCord, winSize & 0xFF),
            "ROI auto exposure set successfully", "Set ROI auto exposure failed")

    @pyqtSlot(result=bool)
    def getAutoExpROIModeAndWindowSize(self) -> bool:
        ok, roi = self._cam.getAutoExpROIMode()
        if ok:
            self.roiAutoExpModeReceived.emit(roi["mode"], roi["wnsize"])
            return True
        return False

    # ---- Gain ----------------------------------------------------------

    @pyqtSlot(result=bool)
    def getGainMode(self) -> bool:
        ok, res = self._cam.getAutoGainMode()
        if ok:
            self.gainModeReceived.emit(res["gain_mode"], res["auto_gain_mode"], res["gain_value"])
            return True
        return False

    @pyqtSlot(int, int, "uint", result=bool)
    def setGainMode(self, gainmode: int, autoModes: int, manualGain: int) -> bool:
        if self._cam.setAutoGainMode(gainmode, autoModes, manualGain & 0xFFFF):
            self.statusChanged.emit("Gain mode set successfully")
            return True
        self.statusChanged.emit("Set gain mode failed")
        return False

    @pyqtSlot(result=bool)
    def getGainLimit(self) -> bool:
        ok, res = self._cam.getAutoGainLimit()
        if ok:
            self.lowerLimitGainReceived.emit(res["lower_limit"])
            self.upperLimitGainReceived.emit(res["upper_limit"])
            return True
        return False

    @pyqtSlot("uint", "uint", result=bool)
    def setGainLimit(self, lowerLimit: int, upperLimit: int) -> bool:
        return self._set(self._cam.setAutoGainLimit(lowerLimit & 0xFFFF, upperLimit & 0xFFFF),
                         "Gain limit set successfully", "Set gain limit failed")

    # ---- Black Level Adjustment --------------------------------------

    @pyqtSlot(int, result=bool)
    def setBlackLevelAdjustment(self, blacklevel: int) -> bool:
        return self._set(self._cam.setBlackLevel(blacklevel),
                         "Black level adjustment set successfully", "Set black level adjustment failed")

    @pyqtSlot(result=bool)
    def getBlackLevelAdjustment(self) -> bool:
        return self._get_value(self._cam.getBlackLevel, self.blackLevelAdjustmentReceived)

    # ---- Target Brightness -------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setTargetBrightness(self, targetBrightness: int) -> bool:
        if self._cam.setBrightness(targetBrightness & 0xFFFF):
            self.statusChanged.emit("Target brightness set successfully")
            return True
        self.statusChanged.emit("Set target brightness failed")
        return False

    @pyqtSlot(result=bool)
    def getTargetBrightness(self) -> bool:
        ok, res = self._cam.getBrightness()
        if ok:
            self.targetBrightnessReceived.emit(res["value"])
            return True
        return False

    # ---- Exposure Mode / Limits --------------------------------------

    @pyqtSlot(int, result=bool)
    def setExposureMode(self, exposureMode: int) -> bool:
        return self._set(self._cam.setAutoExposureMode(exposureMode),
                         "Exposure mode set successfully", "Set exposure mode failed")

    @pyqtSlot(result=bool)
    def getExposureMode(self) -> bool:
        return self._get_value(self._cam.getAutoExposureMode, self.exposureModeReceived)

    @pyqtSlot(result=bool)
    def getExposureLowerLimit(self) -> bool:
        return self._get_value(self._cam.getExposureLowerLimit, self.exposureLowerLimitReceived)

    @pyqtSlot("uint", result=bool)
    def setExposureLowerLimit(self, lowerLimit: int) -> bool:
        return self._set(self._cam.setExposureLowerLimit(lowerLimit),
                         "Exposure lower limit set successfully", "Set exposure lower limit failed")

    @pyqtSlot(result=bool)
    def getExposureUpperLimit(self) -> bool:
        return self._get_value(self._cam.getExposureUpperLimit, self.exposureUpperLimitReceived)

    @pyqtSlot("uint", result=bool)
    def setExposureUpperLimit(self, upperLimit: int) -> bool:
        return self._set(self._cam.setExposureUpperLimit(upperLimit),
                         "Exposure upper limit set successfully", "Set exposure upper limit failed")

    # ---- Anti-Flicker ------------------------------------------------

    @pyqtSlot(int, result=bool)
    def setAntiFlickerMode(self, antiFlickerMode: int) -> bool:
        return self._set(self._cam.setAntiFlickerMode(antiFlickerMode),
                         "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    @pyqtSlot(result=bool)
    def getAntiFlickerMode(self) -> bool:
        return self._get_value(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    # ---- Statistics / Cross-Still ------------------------------------

    @pyqtSlot(result=bool)
    def readStatistics(self) -> bool:
        ok, stats = self._cam.readStatistics()
        if ok:
            self.statisticsReceived.emit(stats["exposure"], stats["gain"])
            return True
        return False

    @pyqtSlot(bool, result=bool)
    def setCrossStillProperties(self, enable: bool) -> bool:
        if self._cam.setCrossStillProperties(enable):
            self.crossStillPropertiesSet.emit(True)
            self.statusChanged.emit("Cross-still properties set successfully")
            return True
        self.crossStillPropertiesSet.emit(False)
        self.statusChanged.emit("Set cross-still properties failed")
        return False

    # ---- Default / Serial / Firmware ---------------------------------

    @pyqtSlot(result=bool)
    def setToDefault(self) -> bool:
        return self._set(self._cam.restoreDefault(),
                         "Camera reset to default successfully", "Set to default failed")

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, serial = self._cam.getCameraUniqueID64()
        if ok:
            self.serialNumberReceived.emit(serial)
            return 1
        return 0

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, version = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        return 0
