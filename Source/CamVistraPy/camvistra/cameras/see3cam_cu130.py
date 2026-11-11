"""See3CAM_CU130 controller.

Port of CamVistra/Model/src/See3CAM_CU130_Model.cpp and
CamVistra/Controller/src/See3CAM_CU130_Controller.cpp.
QML: context property ``see3camcu130Controller``, type ``See3CAMCU130``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU130_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU130

    class sceneModesCU130(enum.IntEnum):
        SCENE_NORMAL = 0x01
        SCENE_PORTRAIT = 0x02
        SCENE_LANDSCAPE = 0x03
        SCENE_SPORT = 0x04
        SCENE_CLOSE_UP = 0x05
        SCENE_NIGHT = 0x06
        SCENE_TWILIGHT = 0x07
        SCENE_BACKLIGHT = 0x08
        SCENE_HIGH_SENSITIVE = 0x09
        SCENE_NIGHT_PORTRAIT = 0x0A
        SCENE_BEACH = 0x0B
        SCENE_DOCUMENT = 0x0C
        SCENE_PARTY = 0x0D
        SCENE_FIREWORKS = 0x0E
        SCENE_SUNSET = 0x0F
        SCENE_AUTO_DETECT = 0x10
    Q_ENUM(sceneModesCU130)

    class specialEffectsCU130(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_ALIEN = 0x02
        EFFECT_ANTIQUE = 0x03
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_EMBOSS = 0x05
        EFFECT_EMBOSS_COLORED = 0x06
        EFFECT_GRAY = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_BLUE = 0x09
        EFFECT_GREEN = 0x0A
        EFFECT_RED = 0x0B
        EFFECT_POSTERIZE_1 = 0x0C
        EFFECT_POSTERIZE_2 = 0x0D
        EFFECT_SEPIA_1 = 0x0E
        EFFECT_SEPIA_2 = 0x0F
        EFFECT_SKETCH = 0x10
        EFFECT_SOLARIZE = 0x11
        EFFECT_FOGGY = 0x12
    Q_ENUM(specialEffectsCU130)

    class flipMirrorControlsCU130(enum.IntEnum):
        FLIP_OFF_MIRROR_OFF = 0x00
        FLIP_ON_MIRROR_OFF = 0x01
        FLIP_OFF_MIRROR_ON = 0x02
        FLIP_ON_MIRROR_ON = 0x03
    Q_ENUM(flipMirrorControlsCU130)

    class camROIAutoExpModeCU130(enum.IntEnum):
        AE_Face = 0x00
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(camROIAutoExpModeCU130)

    class camFaceRectModeCU130(enum.IntEnum):
        FaceRectEnable = 0x01
        FaceRectDisable = 0x00
    Q_ENUM(camFaceRectModeCU130)

    class camFaceDetectEmbedDataModeCU130(enum.IntEnum):
        FaceDetectEmbedDataEnable = 0x01
        FaceDetectEmbedDataDisable = 0x00
    Q_ENUM(camFaceDetectEmbedDataModeCU130)

    class camFaceDetectOverlayRectCU130(enum.IntEnum):
        FaceDetectOverlayRectEnable = 0x01
        FaceDetectOverlayRectDisable = 0x00
    Q_ENUM(camFaceDetectOverlayRectCU130)

    class camSmileDetectModeCU130(enum.IntEnum):
        SmileDetectEnable = 0x01
        SmileDetectDisable = 0x00
    Q_ENUM(camSmileDetectModeCU130)

    class camSmileDetectEmbedDataModeCU130(enum.IntEnum):
        SmileDetectEmbedDataEnable = 0x01
        SmileDetectEmbedDataDisable = 0x00
    Q_ENUM(camSmileDetectEmbedDataModeCU130)

    class camFlickerModeCU130(enum.IntEnum):
        MODE_AUTO = 0x00
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_DISABLE = 0x03
    Q_ENUM(camFlickerModeCU130)

    # Scene / Effect / Denoise
    sceneModeReceived = pyqtSignal(int, arguments=['sceneMode'])
    effectModeReceived = pyqtSignal(int, arguments=['effectMode'])
    denoiseValueReceived = pyqtSignal(int, arguments=['denoiseValue'])
    # Auto Exposure
    roiAutoExpModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    exposureCompReceived = pyqtSignal("uint", arguments=['expComp'])
    # Burst / QFactor / FrameRate
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    frameRateReceived = pyqtSignal(int, arguments=['frameRate'])
    # Stream / Flip / AntiFlicker (streamModeReceived is never emitted in C++ either)
    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    # Face / Smile Detection
    faceDetectModeReceived = pyqtSignal(int, int, int, arguments=['mode', 'embedData', 'overlayRect'])
    smileDetectModeReceived = pyqtSignal(int, int, arguments=['mode', 'embedData'])
    # Serial / Firmware
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

    # ---- Scene / Effect / Denoise ------------------------------------

    @pyqtSlot(result=int)
    def getSceneMode(self) -> int:
        return self._get_u8(self._cam.getSceneMode, self.sceneModeReceived)

    @pyqtSlot(int, result=int)
    def setSceneMode(self, sceneMode: int) -> int:
        return self._set_int(self._cam.setSceneMode(sceneMode),
                             "Scene mode set successfully", "Set scene mode failed")

    @pyqtSlot(result=int)
    def getEffectMode(self) -> int:
        return self._get_u8(self._cam.getSpecialEffects, self.effectModeReceived)

    @pyqtSlot(int, result=int)
    def setEffectMode(self, effectMode: int) -> int:
        return self._set_int(self._cam.setSpecialEffects(effectMode),
                             "Effect mode set successfully", "Set effect mode failed")

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get_u8(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, denoiseVal: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(denoiseVal & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto Exposure -------------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROI(self) -> int:
        ok, v = self._cam.getAutoExpROIMode()
        if ok:
            self.roiAutoExpModeReceived.emit(int(v["mode"]), int(v["wnsize"]))
            return 1
        return 0

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoExpROI(self, roiMode: int, vidW: int, vidH: int,
                      xCord: int, yCord: int, winSize: int) -> int:
        return self._set_int(
            self._cam.setAutoExpROIMode(roiMode, vidW & 0xFFFFFFFF, vidH & 0xFFFFFFFF,
                                        xCord & 0xFFFFFFFF, yCord & 0xFFFFFFFF, winSize & 0xFF),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        ok, value = self._cam.getExposureCompensation()
        if ok:
            self.exposureCompReceived.emit(value)
            return 1
        return 0

    @pyqtSlot("uint", result=int)
    def setExposureCompensation(self, expCompValue: int) -> int:
        return self._set_int(self._cam.setExposureCompensation(expCompValue),
                             "Exposure compensation set successfully", "Set exposure compensation failed")

    # ---- Burst / QFactor / FrameRate -----------------------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_u8(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=int)
    def getQFactor(self) -> int:
        return self._get_u8(self._cam.getQFactor, self.qFactorReceived)

    @pyqtSlot(int, result=int)
    def setQFactor(self, qFactor: int) -> int:
        return self._set_int(self._cam.setQFactor(qFactor & 0xFF),
                             "Q factor set successfully", "Set Q factor failed")

    @pyqtSlot(result=int)
    def getFrameRateCtrlValue(self) -> int:
        return self._get_u8(self._cam.getFrameRateValue, self.frameRateReceived)

    @pyqtSlot(int, result=int)
    def setFrameRateCtrlValue(self, frameRate: int) -> int:
        return self._set_int(self._cam.setFrameRateValue(frameRate & 0xFF),
                             "Frame rate set successfully", "Set frame rate failed")

    # ---- Flip / AntiFlicker ----------------------------------------------

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get_u8(self._cam.getOrientation, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setOrientation(horzFlip, vertFlip),
                             "Flip mode set successfully", "Set flip mode failed")

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_u8(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Face / Smile Detection ------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetectMode(self) -> int:
        ok, v = self._cam.getFaceDetectionRect()
        if ok:
            self.faceDetectModeReceived.emit(int(v["mode"]), int(v["embedData"]), int(v["overlayrect"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetectRect(self, enable: bool, embedData: bool, overlayRect: bool) -> int:
        return self._set_int(self._cam.setFaceDetectionRect(enable, embedData, overlayRect),
                             "Face detection rect set successfully", "Set face detection rect failed")

    @pyqtSlot(result=int)
    def getSmileDetectMode(self) -> int:
        ok, v = self._cam.getSmileDetectionState()
        if ok:
            self.smileDetectModeReceived.emit(int(v["mode"]), int(v["embedData"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, result=int)
    def setSmileDetectRect(self, enable: bool, embedData: bool) -> int:
        return self._set_int(self._cam.setSmileDetectionState(enable, embedData),
                             "Smile detection rect set successfully", "Set smile detection rect failed")

    # ---- Default / Serial / Firmware -------------------------------------

    @pyqtSlot(result=int)
    def setToDefault(self) -> int:
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
