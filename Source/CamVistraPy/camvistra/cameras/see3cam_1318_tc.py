"""See3CAM_1318_TC controller.

Port of CamVistra/Model/src/See3CAM_1318_TC_Model.cpp and
CamVistra/Controller/src/See3CAM_1318_TC_Controller.cpp.
QML: context property ``see3cam1318tcController``, type ``See3CAM1318_TC``.

initialize / initializeFromDevicePath / deinitExtensionUnit behave exactly
like the base class (setHidFd + return 1, initFromDevicePath ? 1 : 0 on
Windows / 0 elsewhere, deinit on Windows only).
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_1318_TC_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_1318_TC

    class SceneMode1318_TC(enum.IntEnum):
        SCENE_NORMAL = 0x01
        SCENE_DOCUMENT = 0x0C
    Q_ENUM(SceneMode1318_TC)

    class SpecialEffect1318_TC(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(SpecialEffect1318_TC)

    class AfMode1318_TC(enum.IntEnum):
        Continuous = 0x01
        OneShot = 0x02
        AfDisabled = 0x03
    Q_ENUM(AfMode1318_TC)

    class AfRect1318_TC(enum.IntEnum):
        Enable = 0x01
        Disable = 0x00
    Q_ENUM(AfRect1318_TC)

    class FaceDetection1318_TC(enum.IntEnum):
        FDEnable = 0x01
        FDDisable = 0x00
        RectEnable = 0x01
        RectDisable = 0x00
        EmbedDataEnable = 0x01
        EmbedDataDisable = 0x00
    Q_ENUM(FaceDetection1318_TC)

    class FlashMode1318_TC(enum.IntEnum):
        DISABLE = 0x00
        STROBE = 0x01
        TORCH = 0x02
    Q_ENUM(FlashMode1318_TC)

    class ROIAfMode1318_TC(enum.IntEnum):
        AF_Centered = 0x01
        AF_Manual = 0x02
        AF_Disabled = 0x03
    Q_ENUM(ROIAfMode1318_TC)

    class ROIAutoExpMode1318_TC(enum.IntEnum):
        AE_Face = 0x00
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(ROIAutoExpMode1318_TC)

    class HDRMode1318_TC(enum.IntEnum):
        HdrOff = 0x01
        HdrAuto = 0x02
        HdrManual = 0x03
    Q_ENUM(HDRMode1318_TC)

    class FlickerMode1318_TC(enum.IntEnum):
        MODE_AUTO = 0x03
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_DISABLE = 0x00
    Q_ENUM(FlickerMode1318_TC)

    class StreamMode1318_TC(enum.IntEnum):
        STREAM_MASTER = 0x00
        STREAM_TRIGGER = 0x01
    Q_ENUM(StreamMode1318_TC)

    class FlipMode1318_TC(enum.IntEnum):
        BOTH_DISABLE = 0x00
        HORZ_ONLY = 0x01
        VERT_ONLY = 0x02
        BOTH_ENABLE = 0x03
    Q_ENUM(FlipMode1318_TC)

    class AutoSaveConfig1318_TC(enum.IntEnum):
        AUTO_SAVE_ENABLE = 0x01
        AUTO_SAVE_DISABLE = 0x00
    Q_ENUM(AutoSaveConfig1318_TC)

    # Scene / Effect / Denoise
    sceneModeReceived = pyqtSignal(int, arguments=['sceneMode'])
    effectModeReceived = pyqtSignal(int, arguments=['effectMode'])
    denoiseValueReceived = pyqtSignal(int, arguments=['denoiseValue'])
    # Auto Focus
    afModeReceived = pyqtSignal(int, arguments=['afMode'])
    roiAfModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    afRectModeReceived = pyqtSignal(int, arguments=['afRectMode'])
    afPositionReceived = pyqtSignal(int, arguments=['afPosition'])
    # Auto Exposure
    roiAutoExpModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    autoExposureReceived = pyqtSignal("uint", arguments=['autoExposure'])
    exposureCompReceived = pyqtSignal("uint", arguments=['expComp'])
    # HDR
    hdrModeReceived = pyqtSignal(int, int, arguments=['hdrMode', 'hdrValue'])
    # Burst / QFactor / FrameRate
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    frameRateReceived = pyqtSignal(int, arguments=['frameRate'])
    # Stream / Flip / AntiFlicker
    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    # Face Detection
    faceDetectModeReceived = pyqtSignal(int, int, int, arguments=['mode', 'embedData', 'overlayRect'])
    # White Balance / Flash
    autoWhiteBalanceReceived = pyqtSignal(int, arguments=['awbValue'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
    # RGB Gains
    redGainReceived = pyqtSignal(int, int, int, arguments=['minVal', 'maxVal', 'currentVal'])
    blueGainReceived = pyqtSignal(int, int, int, arguments=['minVal', 'maxVal', 'currentVal'])
    greenGainReceived = pyqtSignal(int, int, int, arguments=['minVal', 'maxVal', 'currentVal'])
    # Save / Serial
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # Auto Save Configuration
    autoSaveConfigReceived = pyqtSignal(int, arguments=['autoSaveMode'])
    # ------------------------------------------------------------------
    def _get(self, getter, signal) -> int:
        """``uint8_t value; if (get(value)) { emit sig(int(value)); return 1; } return 0;``"""
        ok, value = self._unpack(getter())
        if ok:
            signal.emit(int(value))
            return 1
        return 0

    def _set_int(self, ok, success: str, failure: str) -> int:
        return 1 if self._set(ok, success, failure) else 0

    # ---- Scene / Effect / Denoise ------------------------------------

    @pyqtSlot(result=int)
    def getSceneMode(self) -> int:
        return self._get(self._cam.getSceneMode, self.sceneModeReceived)

    @pyqtSlot(int, result=int)
    def setSceneMode(self, sceneMode: int) -> int:
        return self._set_int(self._cam.setSceneMode(sceneMode),
                             "Scene mode set successfully", "Set scene mode failed")

    @pyqtSlot(result=int)
    def getEffectMode(self) -> int:
        return self._get(self._cam.getEffectMode, self.effectModeReceived)

    @pyqtSlot(int, result=int)
    def setEffectMode(self, effectMode: int) -> int:
        return self._set_int(self._cam.setEffectMode(effectMode),
                             "Effect mode set successfully", "Set effect mode failed")

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, denoiseVal: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(denoiseVal & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto Focus ----------------------------------------------------

    @pyqtSlot(result=int)
    def getAutoFocusMode(self) -> int:
        return self._get(self._cam.getAutoFocusMode, self.afModeReceived)

    @pyqtSlot(int, result=int)
    def setAutoFocusMode(self, afMode: int) -> int:
        return self._set_int(self._cam.setAutoFocusMode(afMode),
                             "AF mode set successfully", "Set AF mode failed")

    @pyqtSlot(result=int)
    def getAutoFocusROI(self) -> int:
        ok, v = self._unpack(self._cam.getAutoFocusROI())
        if ok:
            self.roiAfModeReceived.emit(int(v["mode"]), int(v["winSize"]))
            return 1
        return 0

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoFocusROI(self, roiMode: int, vidW: int, vidH: int,
                        xCord: int, yCord: int, winSize: int) -> int:
        return self._set_int(
            self._cam.setAutoFocusROI(roiMode, vidW & 0xFFFFFFFF, vidH & 0xFFFFFFFF,
                                      xCord & 0xFFFFFFFF, yCord & 0xFFFFFFFF, winSize & 0xFF),
            "AF ROI set successfully", "Set AF ROI failed")

    @pyqtSlot(result=int)
    def getAFRectMode(self) -> int:
        return self._get(self._cam.getAFRectMode, self.afRectModeReceived)

    @pyqtSlot(bool, result=int)
    def enableDisableAFRect(self, enable: bool) -> int:
        if self._cam.enableDisableAFRect(enable):
            self.statusChanged.emit("AF rectangle enabled" if enable else "AF rectangle disabled")
            return 1
        self.statusChanged.emit("AF rectangle toggle failed")
        return 0

    @pyqtSlot(bool, result=int)
    def enableDisableAFRect2(self, enable: bool) -> int:
        if self._cam.enableDisableAFRect2(enable):
            self.statusChanged.emit("AF rectangle 2 enabled" if enable else "AF rectangle 2 disabled")
            return 1
        self.statusChanged.emit("AF rectangle 2 toggle failed")
        return 0

    @pyqtSlot(result=int)
    def getAutoFocusPosition(self) -> int:
        return self._get(self._cam.getAutoFocusPosition, self.afPositionReceived)

    # ---- Auto Exposure -------------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROI(self) -> int:
        ok, v = self._unpack(self._cam.getAutoExpROI())
        if ok:
            self.roiAutoExpModeReceived.emit(int(v["mode"]), int(v["winSize"]))
            return 1
        return 0

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoExpROI(self, roiMode: int, vidW: int, vidH: int,
                      xCord: int, yCord: int, winSize: int) -> int:
        return self._set_int(
            self._cam.setAutoExpROI(roiMode, vidW & 0xFFFFFFFF, vidH & 0xFFFFFFFF,
                                    xCord & 0xFFFFFFFF, yCord & 0xFFFFFFFF, winSize & 0xFF),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    @pyqtSlot(result=int)
    def getAutoExposure(self) -> int:
        return self._get(self._cam.getAutoExposure, self.autoExposureReceived)

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        return self._get(self._cam.getExposureCompensation, self.exposureCompReceived)

    @pyqtSlot("uint", result=int)
    def setExposureCompensation(self, expCompValue: int) -> int:
        return self._set_int(self._cam.setExposureCompensation(expCompValue),
                             "Exposure compensation set successfully", "Set exposure compensation failed")

    # ---- HDR -----------------------------------------------------------

    @pyqtSlot(result=int)
    def getHDRMode(self) -> int:
        ok, v = self._unpack(self._cam.getHDRMode())
        if ok:
            self.hdrModeReceived.emit(int(v["mode"]), int(v["value"]))
            return 1
        return 0

    @pyqtSlot(int, int, result=int)
    def setHDRMode(self, hdrMode: int, hdrValue: int) -> int:
        return self._set_int(self._cam.setHDRMode(hdrMode, hdrValue & 0xFF),
                             "HDR mode set successfully", "Set HDR mode failed")

    # ---- Burst / QFactor / FrameRate -----------------------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=int)
    def getQFactor(self) -> int:
        return self._get(self._cam.getQFactor, self.qFactorReceived)

    @pyqtSlot(int, result=int)
    def setQFactor(self, qFactor: int) -> int:
        return self._set_int(self._cam.setQFactor(qFactor & 0xFF),
                             "Q factor set successfully", "Set Q factor failed")

    @pyqtSlot(result=int)
    def getFrameRateCtrlValue(self) -> int:
        return self._get(self._cam.getFrameRateCtrlValue, self.frameRateReceived)

    @pyqtSlot(int, result=int)
    def setFrameRateCtrlValue(self, frameRate: int) -> int:
        return self._set_int(self._cam.setFrameRateCtrlValue(frameRate & 0xFF),
                             "Frame rate set successfully", "Set frame rate failed")

    # ---- Stream / Flip / AntiFlicker -----------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, streamMode: int) -> int:
        return self._set_int(self._cam.setStreamMode(streamMode),
                             "Stream mode set successfully", "Set stream mode failed")

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get(self._cam.getFlipMode, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setFlipMode(horzFlip, vertFlip),
                             "Flip mode set successfully", "Set flip mode failed")

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Face Detection ------------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetectMode(self) -> int:
        ok, v = self._unpack(self._cam.getFaceDetectMode())
        if ok:
            self.faceDetectModeReceived.emit(int(v["mode"]), int(v["embedData"]), int(v["overlayRect"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetectRect(self, enable: bool, embedData: bool, overlayRect: bool) -> int:
        return self._set_int(self._cam.setFaceDetectRect(enable, embedData, overlayRect),
                             "Face detection rect set successfully", "Set face detection rect failed")

    # ---- White Balance / Flash -----------------------------------------

    @pyqtSlot(result=int)
    def getAutoWhiteBalance(self) -> int:
        return self._get(self._cam.getAutoWhiteBalance, self.autoWhiteBalanceReceived)

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        return self._set_int(self._cam.setFlashMode(flashMode),
                             "Flash mode set successfully", "Set flash mode failed")

    # ---- RGB Gains -----------------------------------------------------

    def _get_gain(self, getter, signal) -> int:
        ok, gain = self._unpack(getter())
        if ok:
            signal.emit(int(gain["min"]), int(gain["max"]), int(gain["current"]))
            return 1
        return 0

    @pyqtSlot(result=int)
    def getRedGain(self) -> int:
        return self._get_gain(self._cam.getRedGain, self.redGainReceived)

    @pyqtSlot(int, result=int)
    def setRedGain(self, redGain: int) -> int:
        return self._set_int(self._cam.setRedGain(redGain & 0xFF),
                             "Red gain set successfully", "Set red gain failed")

    @pyqtSlot(result=int)
    def getBlueGain(self) -> int:
        return self._get_gain(self._cam.getBlueGain, self.blueGainReceived)

    @pyqtSlot(int, result=int)
    def setBlueGain(self, blueGain: int) -> int:
        return self._set_int(self._cam.setBlueGain(blueGain & 0xFF),
                             "Blue gain set successfully", "Set blue gain failed")

    @pyqtSlot(result=int)
    def getGreenGain(self) -> int:
        return self._get_gain(self._cam.getGreenGain, self.greenGainReceived)

    @pyqtSlot(int, result=int)
    def setGreenGain(self, greenGain: int) -> int:
        return self._set_int(self._cam.setGreenGain(greenGain & 0xFF),
                             "Green gain set successfully", "Set green gain failed")

    # ---- Save / Default / Serial / Firmware ----------------------------

    @pyqtSlot(result=int)
    def saveConfiguration(self) -> int:
        return self._set_int(self._cam.saveConfiguration(),
                             "Configuration saved successfully", "Save configuration failed")

    @pyqtSlot(result=int)
    def setToDefault(self) -> int:
        return self._set_int(self._cam.setToDefault(),
                             "Device reset to defaults successfully", "Reset to defaults failed")

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, serial = self._unpack(self._cam.get64BitSerialNumber())
        if ok:
            # snprintf("%016llx"): 16-char zero-padded lower-case hex
            self.serialNumberReceived.emit(format(int(serial) & 0xFFFFFFFFFFFFFFFF, "016x"))
            return 1
        self.statusChanged.emit("Read serial number failed")
        return 0

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, version = self._unpack(self._cam.readFirmwareVersion())
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        self.statusChanged.emit("Read firmware version failed")
        return 0

    # ---- Auto Save Configuration ---------------------------------------

    @pyqtSlot(result=int)
    def getAutoSaveConfig(self) -> int:
        return self._get(self._cam.getAutoSaveConfiguration, self.autoSaveConfigReceived)

    @pyqtSlot(int, result=int)
    def setAutoSaveConfig(self, autoSaveMode: int) -> int:
        return self._set_int(self._cam.setAutoSaveConfiguration(autoSaveMode),
                             "Auto Save Configuration set successfully", "Auto Save Configuration set failed")
