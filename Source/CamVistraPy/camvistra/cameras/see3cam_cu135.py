"""See3CAM_CU135 controller.

Port of CamVistra/Model/src/See3CAM_CU135_Model.cpp and
CamVistra/Controller/src/See3CAM_CU135_Controller.cpp.
QML: context property ``see3camcu135Controller``, type ``See3CAMCU135``.

The C++ Controller re-emits the Model's ``*Received`` signals under different
names (``sceneModeValue``, ``flipMirrorModeChanged``, ...); the merged class
emits the Controller names directly.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk

# EXPOSURE_COMP_MIN/MAX_CU135 (CAMSDK/include/See3CAM_CU135.h)
EXPOSURE_COMP_MIN_CU135 = 8000
EXPOSURE_COMP_MAX_CU135 = 1000000


def _qstring_to_int(text: str) -> int:
    """QString::toInt(): 0 for non-numeric input or values outside int32."""
    try:
        value = int(text.strip(), 10)
    except ValueError:
        return 0
    return value if -2**31 <= value < 2**31 else 0


class See3CAM_CU135_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU135

    class sceneModes(enum.IntEnum):
        SCENE_NORMAL = 0x01
        SCENE_DOCUMENT = 0x0C
    Q_ENUM(sceneModes)

    class specialEffects(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(specialEffects)

    class camiHDRMode(enum.IntEnum):
        HdrOff = 0x01
        HdrAuto = 0x02
        HdrManual = 0x03
    Q_ENUM(camiHDRMode)

    class camStreamMode(enum.IntEnum):
        STREAM_MASTER = 0x00
        STREAM_TRIGGER = 0x01
    Q_ENUM(camStreamMode)

    class camROIAutoExpMode(enum.IntEnum):
        AE_Face = 0x00
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(camROIAutoExpMode)

    class camFaceRectMode(enum.IntEnum):
        FaceRectEnable = 0x01
        FaceRectDisable = 0x00
    Q_ENUM(camFaceRectMode)

    class camFaceDetectEmbedDataMode(enum.IntEnum):
        FaceDetectEmbedDataEnable = 0x01
        FaceDetectEmbedDataDisable = 0x00
    Q_ENUM(camFaceDetectEmbedDataMode)

    class camFaceDetectOverlayRect(enum.IntEnum):
        FaceDetectOverlayRectEnable = 0x01
        FaceDetectOverlayRectDisable = 0x00
    Q_ENUM(camFaceDetectOverlayRect)

    class camSmileDetectMode(enum.IntEnum):
        SmileDetectEnable = 0x01
        SmileDetectDisable = 0x00
    Q_ENUM(camSmileDetectMode)

    class camSmileDetectEmbedDataMode(enum.IntEnum):
        SmileDetectEmbedDataEnable = 0x01
        SmileDetectEmbedDataDisable = 0x00
    Q_ENUM(camSmileDetectEmbedDataMode)

    class flipMirrorControls(enum.IntEnum):
        SetBothFlipDisable = 0
        SetHorzFlip = 1
        SetVertiFlip = 2
        SetBothFlipEnable = 3
    Q_ENUM(flipMirrorControls)

    class camFlickerMode(enum.IntEnum):
        MODE_AUTO = 0x00
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_DISABLE = 0x03
    Q_ENUM(camFlickerMode)

    sceneModeValue = pyqtSignal("uint", arguments=['sceneMode'])
    effectModeValue = pyqtSignal("uint", arguments=['effectMode'])
    denoiseValue = pyqtSignal("uint", arguments=['denoiseVal'])
    qFactorValue = pyqtSignal("uint", arguments=['qFactor'])
    hdrModeValue = pyqtSignal("uint", "uint", arguments=['hdrMode', 'hdrValue'])
    streamModeValue = pyqtSignal("uint", arguments=['streamMode'])
    flipMirrorModeChanged = pyqtSignal("uint", arguments=['flipMirrorMode'])
    burstLengthValue = pyqtSignal("uint", arguments=['burstLength'])
    roiAutoExpMode = pyqtSignal("uint", "uint", arguments=['roiMode', 'winSize'])
    exposureCompValue = pyqtSignal("uint", arguments=['exposureCompensation'])
    frameRateCtrlValue = pyqtSignal("uint", arguments=['frameRateVal'])
    faceDetectModeValue = pyqtSignal("uint", "uint", "uint", arguments=['faceDetectMode', 'faceDetectEmbedDataValue', 'faceDetectOverlayRect'])
    smileDetectModeValue = pyqtSignal("uint", "uint", arguments=['smileDetectMode', 'smileDetectEmbedDataValue'])
    indicateExposureValueRangeFailure = pyqtSignal(str, str, arguments=['title', 'text'])
    flickerDetectionMode = pyqtSignal("uint", arguments=['flickerMode'])
    # ------------------------------------------------------------------
    def _get_value(self, getter, signal) -> bool:
        ok, value = getter()
        if ok:
            signal.emit(value)
            return True
        return False

    # ---- Scene Mode -------------------------------------------------------

    @pyqtSlot(int, result=bool)
    def setSceneMode(self, sceneMode: int) -> bool:
        return self._set(self._cam.setSceneMode(sceneMode & 0xFF),
                         "Scene mode set successfully", "Set scene mode failed")

    @pyqtSlot(result=bool)
    def getSceneMode(self) -> bool:
        return self._get_value(self._cam.getSceneMode, self.sceneModeValue)

    # ---- Effect Mode ------------------------------------------------------

    @pyqtSlot(result=bool)
    def getEffectMode(self) -> bool:
        return self._get_value(self._cam.getSpecialEffects, self.effectModeValue)

    @pyqtSlot(int, result=bool)
    def setEffectMode(self, specialEffect: int) -> bool:
        return self._set(self._cam.setSpecialEffects(specialEffect & 0xFF),
                         "Effect mode set successfully", "Set effect mode failed")

    # ---- Denoise ----------------------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setDenoiseValue(self, deNoiseVal: int) -> bool:
        return self._set(self._cam.setDenoiseValue(deNoiseVal & 0xFF),
                         "Denoise value set successfully", "Set denoise value failed")

    @pyqtSlot(result=bool)
    def getDenoiseValue(self) -> bool:
        return self._get_value(self._cam.getDenoiseValue, self.denoiseValue)

    # ---- Q Factor ---------------------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setQFactor(self, qFactor: int) -> bool:
        return self._set(self._cam.setQFactor(qFactor & 0xFF),
                         "Q factor set successfully", "Set Q factor failed")

    @pyqtSlot(result=bool)
    def getQFactor(self) -> bool:
        return self._get_value(self._cam.getQFactor, self.qFactorValue)

    # ---- iHDR Mode --------------------------------------------------------

    @pyqtSlot(int, "uint", result=bool)
    def setiHDRMode(self, iHDRMode: int, iHDRValue: int) -> bool:
        return self._set(self._cam.setHDRMode(iHDRMode & 0xFF, iHDRValue & 0xFF),
                         "iHDR mode set successfully", "Set iHDR mode failed")

    @pyqtSlot(result=bool)
    def getiHDRMode(self) -> bool:
        ok, hdr = self._cam.getHDRMode()
        if ok:
            self.hdrModeValue.emit(hdr["mode"], hdr["value"])
            return True
        return False

    # ---- Stream Mode ------------------------------------------------------

    @pyqtSlot(int, result=bool)
    def setStreamMode(self, streamMode: int) -> bool:
        return self._set(self._cam.setStreamMode(streamMode & 0xFF),
                         "Stream mode set successfully", "Set stream mode failed")

    @pyqtSlot(result=bool)
    def getStreamMode(self) -> bool:
        return self._get_value(self._cam.getStreamMode, self.streamModeValue)

    # ---- Flicker Detection ------------------------------------------------

    @pyqtSlot(int, result=bool)
    def setFlickerDetection(self, flickerMode: int) -> bool:
        return self._set(self._cam.setFlickerDetection(flickerMode & 0xFF),
                         "Flicker detection set successfully", "Set flicker detection failed")

    @pyqtSlot(result=bool)
    def getFlickerDetection(self) -> bool:
        return self._get_value(self._cam.getFlickerDetection, self.flickerDetectionMode)

    # ---- Orientation (Flip/Mirror) ----------------------------------------

    @pyqtSlot(bool, bool, result=bool)
    def setOrientation(self, horzModeSel: bool, vertiModeSel: bool) -> bool:
        return self._set(self._cam.setOrientation(bool(horzModeSel), bool(vertiModeSel)),
                         "Orientation set successfully", "Set orientation failed")

    @pyqtSlot(result=bool)
    def getOrientation(self) -> bool:
        return self._get_value(self._cam.getOrientation, self.flipMirrorModeChanged)

    # ---- Burst Length -----------------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setBurstLength(self, burstLength: int) -> bool:
        return self._set(self._cam.setBurstLength(burstLength & 0xFF),
                         "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=bool)
    def getBurstLength(self) -> bool:
        return self._get_value(self._cam.getBurstLength, self.burstLengthValue)

    # ---- ROI Auto Exposure ------------------------------------------------

    @pyqtSlot(int, "uint", "uint", "uint", "uint", str, result=bool)
    def setROIAutoExposure(self, see3camAutoexpROIMode: int, vidResolnWidth: int, vidResolnHeight: int,
                           xCord: int, yCord: int, winSize: str) -> bool:
        winSizeVal = _qstring_to_int(winSize) & 0xFF
        return self._set(
            self._cam.setExpROIMode(see3camAutoexpROIMode & 0xFF, vidResolnWidth, vidResolnHeight,
                                    xCord, yCord, winSizeVal),
            "ROI auto exposure set successfully", "Set ROI auto exposure failed")

    @pyqtSlot(result=bool)
    def getAutoExpROIModeAndWindowSize(self) -> bool:
        ok, roi = self._cam.getExpROIMode()
        if ok:
            self.roiAutoExpMode.emit(roi["mode"], roi["wnsize"])
            return True
        return False

    # ---- Exposure Compensation --------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setExposureCompensation(self, exposureCompValue: int) -> bool:
        if not EXPOSURE_COMP_MIN_CU135 <= exposureCompValue <= EXPOSURE_COMP_MAX_CU135:
            self.indicateExposureValueRangeFailure.emit("Exposure Compensation", "Value out of range")
            self.statusChanged.emit("Set exposure compensation failed: value out of range")
            return False
        return self._set(self._cam.setExposureCompensation(exposureCompValue & 0xFFFFFFFF),
                         "Exposure compensation set successfully", "Set exposure compensation failed")

    @pyqtSlot(result=bool)
    def getExposureCompensation(self) -> bool:
        return self._get_value(self._cam.getExposureCompensation, self.exposureCompValue)

    # ---- Frame Rate Control -----------------------------------------------

    @pyqtSlot("uint", result=bool)
    def setFrameRateCtrlValue(self, frameRate: int) -> bool:
        return self._set(self._cam.setFrameRateCtrlValue(frameRate & 0xFF),
                         "Frame rate set successfully", "Set frame rate failed")

    @pyqtSlot(result=bool)
    def getFrameRateCtrlValue(self) -> bool:
        return self._get_value(self._cam.getFrameRateCtrlValue, self.frameRateCtrlValue)

    # ---- Face Detection ---------------------------------------------------

    @pyqtSlot(bool, bool, bool, result=bool)
    def setFaceDetectionRect(self, enableFaceDetectRect: bool, embedData: bool, overlayRect: bool) -> bool:
        return self._set(self._cam.setFaceDetectionRect(bool(enableFaceDetectRect), bool(embedData),
                                                        bool(overlayRect)),
                         "Face detection set successfully", "Set face detection failed")

    @pyqtSlot(result=bool)
    def getFaceDetectMode(self) -> bool:
        ok, face = self._cam.getFaceDetectionRect()
        if ok:
            self.faceDetectModeValue.emit(face["state"], face["embedData"], face["overlayrect"])
            return True
        return False

    # ---- Smile Detection --------------------------------------------------

    @pyqtSlot(bool, bool, result=bool)
    def setSmileDetection(self, enableSmileDetect: bool, embedData: bool) -> bool:
        return self._set(self._cam.setSmileDetection(bool(enableSmileDetect), bool(embedData)),
                         "Smile detection set successfully", "Set smile detection failed")

    @pyqtSlot(result=bool)
    def getSmileDetectMode(self) -> bool:
        ok, smile = self._cam.getSmileDetection()
        if ok:
            self.smileDetectModeValue.emit(smile["state"], smile["embedData"])
            return True
        return False

    # ---- Face Rectangle Control / Default ---------------------------------

    @pyqtSlot(bool, result=bool)
    def enableDisableFaceRectangle(self, enableRFRect: bool) -> bool:
        return self._set(self._cam.enableDisableFaceRectangle(bool(enableRFRect)),
                         "Face rectangle control set successfully", "Set face rectangle control failed")

    @pyqtSlot(result=bool)
    def setToDefault(self) -> bool:
        return self._set(self._cam.setToDefault(),
                         "Settings reset to default successfully", "Reset to default failed")
