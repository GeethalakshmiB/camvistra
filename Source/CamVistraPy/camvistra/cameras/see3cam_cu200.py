"""See3CAM_CU200 controller.

Port of CamVistra/Model/src/See3CAM_CU200_Model.cpp and
CamVistra/Controller/src/See3CAM_CU200_Controller.cpp.
QML: context property ``see3camcu200Controller``, type ``See3CAMCU200``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk

EXPOSURE_MIN_CU200 = 100
EXPOSURE_MAX_CU200 = 1000000

_RANGE = ("min", "max", "step", "current")


def _qstring_to_uint(text: str) -> int:
    """QString::toUInt(): 0 for non-numeric, negative or > UINT32_MAX input."""
    try:
        value = int(text.strip(), 10)
    except ValueError:
        return 0
    return value if 0 <= value <= 0xFFFFFFFF else 0


class See3CAM_CU200_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU200

    class CameraMode(enum.IntEnum):
        MASTER_MODE = 0x00
        TRIGGER_MODE = 0x01
    Q_ENUM(CameraMode)

    class ExposureMode(enum.IntEnum):
        AUTO_EXPOSURE = 0x00
        MANUAL_EXPOSURE = 0x01
    Q_ENUM(ExposureMode)

    class AutoExposureFeature(enum.IntEnum):
        CONTINIOUS_EXPOSURE = 0x00
        SINGLE_SHOT_EXPOSURE = 0x01
    Q_ENUM(AutoExposureFeature)

    class StrobeMode(enum.IntEnum):
        STROBE_OFF = 0x00
        STROBE_ON = 0x01
    Q_ENUM(StrobeMode)

    class Orientation(enum.IntEnum):
        NORMAL = 0x00
        HORIZONTAL = 0x01
        VERTICAL = 0x02
        ROTATE_180 = 0x03
    Q_ENUM(Orientation)

    class SaveConfiguration(enum.IntEnum):
        SAVE_DEFAULT = 0x00
        SAVE_USER_DEFINED = 0x01
    Q_ENUM(SaveConfiguration)

    class WhiteBalanceMode(enum.IntEnum):
        AUTO_WB = 0x00
        MANUAL_WB = 0x01
    Q_ENUM(WhiteBalanceMode)

    class AutoWbFeature(enum.IntEnum):
        WB_CONTINIOUS = 0x00
        WB_SINGLE_SHOT = 0x01
    Q_ENUM(AutoWbFeature)

    class ManualWbMode(enum.IntEnum):
        WB_COLOR_TEMPERATURE = 0x00
        WB_PRESET_MODE = 0x01
        WB_PRO_MODE = 0x02
    Q_ENUM(ManualWbMode)

    class WbPreset(enum.IntEnum):
        HZ_2300K = 0x00
        A_2800K = 0x01
        U30_3000K = 0x02
        TL84_4000K = 0x03
        CWF_4100K = 0x04
        D50_5000K = 0x05
        D60_6000K = 0x06
        D65_6500K = 0x07
    Q_ENUM(WbPreset)

    class AutoExpRoiMode(enum.IntEnum):
        FULL_ROI = 0x00
        MANUAL_ROI = 0x01
    Q_ENUM(AutoExpRoiMode)

    class AntiFlickerMode(enum.IntEnum):
        MODE_50Hz = 0x00
        MODE_60Hz = 0x01
        MODE_DISABLE = 0x02
    Q_ENUM(AntiFlickerMode)

    brightnessReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    contrastReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    saturationReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    gammaReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    sharpnessReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    blackLevelReceived = pyqtSignal("uint", "uint", "uint", "uint", arguments=['min', 'max', 'step', 'current'])
    targetBrightnessReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    colorTemperatureReceived = pyqtSignal("uint", "uint", "uint", "uint", arguments=['min', 'max', 'step', 'current'])
    rGainReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    bGainReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    colorCorrectionMatrixReceived = pyqtSignal(float, float, float, float, float, float, float, float, float, arguments=['Rr', 'Rg', 'Rb', 'Gr', 'Gg', 'Gb', 'Br', 'Bg', 'Bb'])
    exposureReceived = pyqtSignal("uint", "uint", "uint", arguments=['mode', 'autoFeature', 'manualValue'])
    exposureCompensationReceived = pyqtSignal("uint", arguments=['value'])
    autoGainUpperLimitReceived = pyqtSignal("uint", "uint", "uint", "uint", arguments=['min', 'max', 'step', 'current'])
    autoExpROIReceived = pyqtSignal("uint", "uint", arguments=['roiMode', 'winSize'])
    cameraModeReceived = pyqtSignal("uint", arguments=['cameraMode'])
    strobeModeReceived = pyqtSignal("uint", arguments=['strobeMode'])
    orientationReceived = pyqtSignal("uint", arguments=['flipMode'])
    antiFlickerModeReceived = pyqtSignal("uint", arguments=['antiFlicker'])
    whiteBalanceReceived = pyqtSignal("uint", "uint", "uint", arguments=['mode', 'autoFeature', 'manualFeature'])
    whiteBalancePresetReceived = pyqtSignal("uint", arguments=['presetMode'])
    denoiseFlagReceived = pyqtSignal(bool, arguments=['flag'])
    denoiseStrengthReceived = pyqtSignal(float, float, float, float, arguments=['min', 'max', 'step', 'current'])
    statisticsReceived = pyqtSignal("uint", "uint", float, float,
                                    float, float, float, float, float, float, float, float, float, arguments=['exposure', 'autoGain', 'rGain', 'bGain', 'Rr', 'Rg', 'Rb', 'Gr', 'Gg', 'Gb', 'Br', 'Bg', 'Bb'])
    ispFirmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_range(self, getter, signal) -> bool:
        ok, value = getter()
        if ok:
            signal.emit(*(value[k] for k in _RANGE))
        return ok

    # ---- Brightness / Contrast / Saturation / Gamma / Sharpness ------

    @pyqtSlot(result=bool)
    def getBrightness(self) -> bool:
        return self._get_range(self._cam.getBrightness, self.brightnessReceived)

    @pyqtSlot(float, result=bool)
    def setBrightness(self, brightness: float) -> bool:
        return self._set(self._cam.setBrightness(brightness),
                         "Brightness set successfully", "Set brightness failed")

    @pyqtSlot(result=bool)
    def getContrast(self) -> bool:
        return self._get_range(self._cam.getContrast, self.contrastReceived)

    @pyqtSlot("uint", result=bool)
    def setContrast(self, contrast: int) -> bool:
        return self._set(self._cam.setContrast(contrast & 0xFF),
                         "Contrast set successfully", "Set contrast failed")

    @pyqtSlot(result=bool)
    def getSaturation(self) -> bool:
        return self._get_range(self._cam.getSaturation, self.saturationReceived)

    @pyqtSlot(float, result=bool)
    def setSaturation(self, saturation: float) -> bool:
        return self._set(self._cam.setSaturation(saturation),
                         "Saturation set successfully", "Set saturation failed")

    @pyqtSlot(result=bool)
    def getGammaCorrection(self) -> bool:
        return self._get_range(self._cam.getGammaCorrection, self.gammaReceived)

    @pyqtSlot(float, result=bool)
    def setGammaCorrection(self, gamma: float) -> bool:
        return self._set(self._cam.setGammaCorrection(gamma),
                         "Gamma set successfully", "Set gamma failed")

    @pyqtSlot(result=bool)
    def getSharpnessStrength(self) -> bool:
        return self._get_range(self._cam.getSharpnessStrength, self.sharpnessReceived)

    @pyqtSlot(float, result=bool)
    def setSharpnessStrength(self, sharpness: float) -> bool:
        return self._set(self._cam.setSharpnessStrength(sharpness),
                         "Sharpness set successfully", "Set sharpness failed")

    # ---- Black Level / Target Brightness / Color Temperature ---------

    @pyqtSlot(result=bool)
    def getBlackLevel(self) -> bool:
        return self._get_range(self._cam.getBlackLevel, self.blackLevelReceived)

    @pyqtSlot("uint", result=bool)
    def setBlackLevel(self, blackLevel: int) -> bool:
        return self._set(self._cam.setBlackLevel(blackLevel & 0xFFFF),
                         "Black level set successfully", "Set black level failed")

    @pyqtSlot(result=bool)
    def getTargetBrightness(self) -> bool:
        ok, v = self._cam.getTargetBrightness()
        if ok:
            self.targetBrightnessReceived.emit(float(v["min"]), float(v["max"]),
                                               float(v["step"]), float(v["current"]))
        return ok

    @pyqtSlot("uint", result=bool)
    def setTargetBrightness(self, targetBrightness: int) -> bool:
        return self._set(self._cam.setTargetBrightness(targetBrightness & 0xFFFF),
                         "Target brightness set successfully", "Set target brightness failed")

    @pyqtSlot(result=bool)
    def getColorTemperature(self) -> bool:
        return self._get_range(self._cam.getColorTemperature, self.colorTemperatureReceived)

    @pyqtSlot("uint", result=bool)
    def setColorTemperature(self, colorTemp: int) -> bool:
        return self._set(self._cam.setColorTemperature(colorTemp & 0xFFFF),
                         "Color temperature set successfully", "Set color temperature failed")

    # ---- RGB Gain / Color Correction Matrix ---------------------------

    @pyqtSlot(result=bool)
    def getRBGain(self) -> bool:
        ok, v = self._cam.getRBGain()
        if ok:
            self.rGainReceived.emit(*(v["rGain"][k] for k in _RANGE))
            self.bGainReceived.emit(*(v["bGain"][k] for k in _RANGE))
        return ok

    @pyqtSlot(float, float, result=bool)
    def setRBGain(self, rGain: float, bGain: float) -> bool:
        return self._set(self._cam.setRBGain(rGain, bGain),
                         "RB gain set successfully", "Set RB gain failed")

    _CCM = ("Rr", "Rg", "Rb", "Gr", "Gg", "Gb", "Br", "Bg", "Bb")

    @pyqtSlot(result=bool)
    def getColorCorrectionMatrix(self) -> bool:
        ok, v = self._cam.getColorCorrectionMatrix()
        if ok:
            self.colorCorrectionMatrixReceived.emit(*(v[k] for k in self._CCM))
        return ok

    @pyqtSlot(float, float, float, float, float, float, float, float, float, result=bool)
    def setColorCorrectionMatrix(self, Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb) -> bool:
        matrix = dict(zip(self._CCM, (Rr, Rg, Rb, Gr, Gg, Gb, Br, Bg, Bb)))
        return self._set(self._cam.setColorCorrectionMatrix(matrix),
                         "Color correction matrix set successfully", "Set color correction matrix failed")

    # ---- Exposure -------------------------------------------------------

    @pyqtSlot(result=bool)
    def getExposure(self) -> bool:
        ok, v = self._cam.getExposure()
        if ok:
            self.exposureReceived.emit(v["mode"], v["autoFeature"], v["manualExposure"])
        return ok

    @pyqtSlot(int, int, "uint", result=bool)
    def setExposure(self, mode: int, autoFeature: int, manualExposure: int) -> bool:
        if manualExposure < EXPOSURE_MIN_CU200 or manualExposure > EXPOSURE_MAX_CU200:
            self.statusChanged.emit("Given exposure value is invalid")
            return False
        return self._set(self._cam.setExposure(mode, autoFeature, manualExposure),
                         "Exposure set successfully", "Exposure set failed")

    @pyqtSlot(result=bool)
    def getExposureCompensation(self) -> bool:
        ok, v = self._cam.getExposureCompensation()
        if ok:
            self.exposureCompensationReceived.emit(v)
        return ok

    @pyqtSlot("uint", result=bool)
    def setExposureCompensation(self, exposureCompensation: int) -> bool:
        return self._set(self._cam.setExposureCompensation(exposureCompensation),
                         "Exposure compensation set successfully", "Exposure compensation set failed")

    @pyqtSlot(result=bool)
    def getAutoGainUpperLimit(self) -> bool:
        return self._get_range(self._cam.getAutoGainUpperLimit, self.autoGainUpperLimitReceived)

    @pyqtSlot("uint", result=bool)
    def setAutoGainUpperLimit(self, upperLimit: int) -> bool:
        return self._set(self._cam.setAutoGainUpperLimit(upperLimit & 0xFF),
                         "Auto gain upper limit set successfully", "Set auto gain upper limit failed")

    @pyqtSlot(result=bool)
    def getAutoExpROIModeAndWindowSize(self) -> bool:
        ok, v = self._cam.getAutoExpRoiModeAndWindowSize()
        if ok:
            self.autoExpROIReceived.emit(v["mode"], v["windowSize"])
        return ok

    @pyqtSlot(int, "uint", "uint", "uint", "uint", str, result=bool)
    def setROIAutoExposure(self, roiMode: int, vidResolnWidth: int, vidResolnHeight: int,
                           xCord: int, yCord: int, winSize: str) -> bool:
        win = _qstring_to_uint(winSize) & 0xFF
        return self._set(
            self._cam.setRoiAutoExposure(roiMode, vidResolnWidth, vidResolnHeight, xCord, yCord, win),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    # ---- Camera Mode / Strobe / Orientation / Anti-Flicker ------------

    @pyqtSlot(result=bool)
    def getCameraMode(self) -> bool:
        ok, v = self._cam.getCameraMode()
        if ok:
            self.cameraModeReceived.emit(v)
        return ok

    @pyqtSlot(int, result=bool)
    def setCameraMode(self, camMode: int) -> bool:
        return self._set(self._cam.setCameraMode(camMode),
                         "Camera mode set successfully", "Set camera mode failed")

    @pyqtSlot(result=bool)
    def getStrobeMode(self) -> bool:
        ok, v = self._cam.getStrobeMode()
        if ok:
            self.strobeModeReceived.emit(v)
        return ok

    @pyqtSlot(int, result=bool)
    def setStrobeMode(self, strobeMode: int) -> bool:
        return self._set(self._cam.setStrobeMode(strobeMode),
                         "Strobe mode set successfully", "Set strobe mode failed")

    @pyqtSlot(result=bool)
    def getOrientation(self) -> bool:
        ok, v = self._cam.getOrientation()
        if ok:
            self.orientationReceived.emit(v)
        return ok

    @pyqtSlot(bool, bool, result=bool)
    def setOrientation(self, horzModeSel: bool, vertiModeSel: bool) -> bool:
        return self._set(self._cam.setOrientation(horzModeSel, vertiModeSel),
                         "Orientation set successfully", "Set orientation failed")

    @pyqtSlot(result=bool)
    def getAntiFlickerMode(self) -> bool:
        ok, v = self._cam.getAntiFlickerMode()
        if ok:
            self.antiFlickerModeReceived.emit(v)
        return ok

    @pyqtSlot(int, result=bool)
    def setAntiFlickerMode(self, antiFlickerMode: int) -> bool:
        return self._set(self._cam.setAntiFlickerMode(antiFlickerMode),
                         "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- White Balance ------------------------------------------------

    @pyqtSlot(result=bool)
    def getWhiteBalanceMode(self) -> bool:
        ok, v = self._cam.getWhiteBalanceMode()
        if ok:
            self.whiteBalanceReceived.emit(v["mode"], v["autoFeature"], v["manualFeature"])
            self.whiteBalancePresetReceived.emit(v["presetMode"])
        return ok

    @pyqtSlot(int, int, int, int, result=bool)
    def setWhiteBalanceMode(self, mode: int, autoFeature: int, manualFeature: int, presetMode: int) -> bool:
        return self._set(self._cam.setWhiteBalanceMode(mode, autoFeature, manualFeature, presetMode),
                         "White balance mode set successfully", "Set white balance mode failed")

    # ---- Denoise / Cross-Still ----------------------------------------

    @pyqtSlot(result=bool)
    def getDenoiseFlag(self) -> bool:
        ok, v = self._cam.getDenoiseFlag()
        if ok:
            self.denoiseFlagReceived.emit(v)
        return ok

    @pyqtSlot(bool, result=bool)
    def enableDisableDenoising(self, flag: bool) -> bool:
        return self._set(self._cam.enableDisableDenoising(flag),
                         "Denoising enable/disable set successfully", "Set denoising enable/disable failed")

    @pyqtSlot(result=bool)
    def getDenoiseStrength(self) -> bool:
        return self._get_range(self._cam.getDenoiseStrength, self.denoiseStrengthReceived)

    @pyqtSlot(float, result=bool)
    def setDenoiseStrength(self, denoiseStrength: float) -> bool:
        return self._set(self._cam.setDenoiseStrength(denoiseStrength),
                         "Denoise strength set successfully", "Set denoise strength failed")

    @pyqtSlot(bool, result=bool)
    def setPropertiesForCrossStill(self, isEnable: bool) -> bool:
        return self._set(self._cam.setPropertiesForCrossStill(isEnable),
                         "Cross-still properties set successfully", "Set cross-still properties failed")

    # ---- Statistics / Save / Reset / Firmware / Default ---------------

    @pyqtSlot(result=bool)
    def readStatistics(self) -> bool:
        ok, v = self._cam.readStatistics()
        if ok:
            ccm = v["ccm"]
            self.statisticsReceived.emit(v["currentExposure"], v["autoGainStatus"], v["rGain"], v["bGain"],
                                         *(ccm[k] for k in self._CCM))
        return ok

    @pyqtSlot(int, result=bool)
    def saveConfiguration(self, configType: int) -> bool:
        return self._set(self._cam.saveConfiguration(configType),
                         "Configuration saved successfully", "Save configuration failed")

    @pyqtSlot(result=bool)
    def resetDevice(self) -> bool:
        return self._set(self._cam.resetDevice(), "Device reset successfully", "Device reset failed")

    @pyqtSlot(result=bool)
    def readISPFirmwareVersion(self) -> bool:
        ok, v = self._cam.readISPFirmwareVersion()
        if ok:
            self.ispFirmwareVersionReceived.emit(v)
        return ok

    @pyqtSlot(result=bool)
    def setToDefault(self) -> bool:
        return self._set(self._cam.setToDefault(),
                         "Settings reset to default successfully", "Reset to default failed")

    @pyqtSlot(result=bool)
    def get64BitSerialNumber(self) -> bool:
        ok, serial = self._cam.getCameraUniqueID64()
        if ok:
            self.serialNumberReceived.emit(serial)
            return True
        self.statusChanged.emit("Read serial number failed")
        return False

    @pyqtSlot(result=bool)
    def getFirmwareVersion(self) -> bool:
        ok, version = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(version)
            return True
        self.statusChanged.emit("Read firmware version failed")
        return False
