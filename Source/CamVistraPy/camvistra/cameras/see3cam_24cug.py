"""See3CAM_24CUG controller.

Port of CamVistra/Model/src/See3CAM_24CUG_Model.cpp and
CamVistra/Controller/src/See3CAM_24CUG_Controller.cpp.
QML: context property ``see3cam24cugController``, type ``See3CAM24CUG``.
"""

from __future__ import annotations

import enum
import re

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk

_INT_RE = re.compile(r"^[+-]?[0-9]+$")


def _qstring_to_int(text: str) -> int:
    """QString::toInt(): base 10, surrounding whitespace ignored, 0 on error/overflow."""
    s = text.strip()
    if not _INT_RE.match(s):
        return 0
    value = int(s)
    return value if -(1 << 31) <= value < (1 << 31) else 0


class See3CAM_24CUG_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_24CUG

    class streamModes(enum.IntEnum):
        MODE_MASTER = 0x00
        MODE_TRIGGER = 0x01
    Q_ENUM(streamModes)

    class specialEffects(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(specialEffects)

    class camROIAutoExpMode(enum.IntEnum):
        AE_Face = 0x00
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(camROIAutoExpMode)

    class flipMirrorControls(enum.IntEnum):
        FLIP_OFF_MIRROR_OFF = 0x00
        FLIP_ON_MIRROR_OFF = 0x01
        FLIP_OFF_MIRROR_ON = 0x02
        FLIP_ON_MIRROR_ON = 0x03
    Q_ENUM(flipMirrorControls)

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

    class flashStateValues(enum.IntEnum):
        FLASHMODE_OFF = 0x00
        FLASHMODE_STROBE = 0x01
    Q_ENUM(flashStateValues)

    class camFlickerMode(enum.IntEnum):
        MODE_DISABLE = 0x00
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_AUTO = 0x03
    Q_ENUM(camFlickerMode)

    sendEffectMode = pyqtSignal("uint", arguments=['effectMode'])
    sendDenoiseValue = pyqtSignal("uint", arguments=['denoiseValue'])
    roiAutoExpModeValue = pyqtSignal("uint", "uint", arguments=['roiMode', 'winSize'])
    burstLengthValue = pyqtSignal("uint", arguments=['burstLength'])
    qFactorValue = pyqtSignal("uint", arguments=['qFactor'])
    flipMirrorModeChanged = pyqtSignal("uint", arguments=['flipMirrorMode'])
    frameRateCtrlValueReceived = pyqtSignal("uint", arguments=['frameRateCtrlValue'])
    exposureCompValueReceived = pyqtSignal("uint", arguments=['exposureCompensation'])
    faceDetectModeValue = pyqtSignal("uint", "uint", "uint", arguments=['faceDetectMode', 'faceDetectEmbedDataValue', 'faceDetectOverlayRect'])
    flashModeValue = pyqtSignal("uint", arguments=['flashMode'])
    flickerDetectionMode = pyqtSignal("uint", arguments=['flickerMode'])
    streamModeValue = pyqtSignal("uint", bool, arguments=['streamMode', 'autoFunctionLock'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_u8(self, getter, signal) -> bool:
        ok, value = getter()
        if ok:
            signal.emit(int(value))
            return True
        return False

    # ---- Effect / Denoise ---------------------------------------------

    @pyqtSlot(result=bool)
    def getEffectMode(self) -> bool:
        return self._get_u8(self._cam.getEffectMode, self.sendEffectMode)

    @pyqtSlot(int, result=bool)
    def setEffectMode(self, specialEffect: int) -> bool:
        # Model takes uint8_t: the enum is narrowed before the SDK cast.
        return self._set(self._cam.setEffectMode(specialEffect & 0xFF),
                         "Effect mode set successfully", "Set effect mode failed")

    @pyqtSlot(result=bool)
    def getDenoiseValue(self) -> bool:
        return self._get_u8(self._cam.getDenoiseValue, self.sendDenoiseValue)

    @pyqtSlot(int, result=bool)
    def setDenoiseValue(self, deNoiseVal: int) -> bool:
        return self._set(self._cam.setDenoiseValue(deNoiseVal & 0xFF),
                         "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto Exposure ROI --------------------------------------------

    @pyqtSlot(result=bool)
    def getAutoExpROIModeAndWindowSize(self) -> bool:
        ok, v = self._cam.getAutoExpROIMode()
        if ok:
            self.roiAutoExpModeValue.emit(int(v["mode"]), int(v["wnsize"]))
            return True
        return False

    @pyqtSlot(int, "uint", "uint", "uint", "uint", str, result=bool)
    def setROIAutoExposure(self, see3camAutoexpROIMode: int, vidResolnWidth: int, vidResolnHeight: int,
                           xCord: int, yCord: int, winSize: str) -> bool:
        return self._set(
            self._cam.setAutoExpROIMode(see3camAutoexpROIMode & 0xFF, vidResolnWidth, vidResolnHeight,
                                        xCord, yCord, _qstring_to_int(winSize) & 0xFF),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    # ---- Burst / QFactor ------------------------------------------------

    @pyqtSlot(result=bool)
    def getBurstLength(self) -> bool:
        return self._get_u8(self._cam.getBurstLength, self.burstLengthValue)

    @pyqtSlot("uint", result=bool)
    def setBurstLength(self, burstLength: int) -> bool:
        return self._set(self._cam.setBurstLength(burstLength & 0xFF),
                         "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=bool)
    def getQFactor(self) -> bool:
        return self._get_u8(self._cam.getQFactor, self.qFactorValue)

    @pyqtSlot("uint", result=bool)
    def setQFactor(self, qFactor: int) -> bool:
        return self._set(self._cam.setQFactor(qFactor & 0xFF),
                         "Q factor set successfully", "Set Q factor failed")

    # ---- Orientation / Frame Rate / Exposure Compensation -------------

    @pyqtSlot(result=bool)
    def getOrientation(self) -> bool:
        return self._get_u8(self._cam.getFlipMode, self.flipMirrorModeChanged)

    @pyqtSlot(bool, bool, result=bool)
    def setOrientation(self, horzModeSel: bool, vertiModeSel: bool) -> bool:
        return self._set(self._cam.setFlipMode(horzModeSel, vertiModeSel),
                         "Orientation set successfully", "Set orientation failed")

    @pyqtSlot(result=bool)
    def getFrameRateCtrlValue(self) -> bool:
        return self._get_u8(self._cam.getFrameRateCtrlValue, self.frameRateCtrlValueReceived)

    @pyqtSlot("uint", result=bool)
    def setFrameRateCtrlValue(self, frameRate: int) -> bool:
        return self._set(self._cam.setFrameRateCtrlValue(frameRate & 0xFF),
                         "Frame rate set successfully", "Set frame rate failed")

    @pyqtSlot(result=bool)
    def getExposureCompensation(self) -> bool:
        ok, value = self._cam.getExposureCompensation()
        if ok:
            self.exposureCompValueReceived.emit(value)
            return True
        return False

    @pyqtSlot("uint", result=bool)
    def setExposureCompensation(self, exposureCompValue: int) -> bool:
        return self._set(self._cam.setExposureCompensation(exposureCompValue),
                         "Exposure compensation set successfully", "Set exposure compensation failed")

    # ---- Face Detection -------------------------------------------------

    @pyqtSlot(result=bool)
    def getFaceDetectMode(self) -> bool:
        ok, v = self._cam.getFaceDetectMode()
        if ok:
            self.faceDetectModeValue.emit(int(v["state"]), int(v["embedData"]), int(v["overlayrect"]))
            return True
        return False

    @pyqtSlot(bool, bool, bool, result=bool)
    def setFaceDetectionRect(self, enableFaceDetectRect: bool, embedData: bool, overlayRect: bool) -> bool:
        return self._set(self._cam.setFaceDetectionRect(enableFaceDetectRect, embedData, overlayRect),
                         "Face detection rect set successfully", "Set face detection rect failed")

    # ---- Flicker / Flash / Stream Mode ---------------------------------

    @pyqtSlot(result=bool)
    def getFlickerDetection(self) -> bool:
        return self._get_u8(self._cam.getFlickerDetection, self.flickerDetectionMode)

    @pyqtSlot(int, result=bool)
    def setFlickerDetection(self, flickerMode: int) -> bool:
        return self._set(self._cam.setFlickerDetection(flickerMode & 0xFF),
                         "Flicker detection mode set successfully", "Set flicker detection mode failed")

    @pyqtSlot(result=bool)
    def getFlashState(self) -> bool:
        return self._get_u8(self._cam.getFlashState, self.flashModeValue)

    @pyqtSlot(int, result=bool)
    def setFlashState(self, flashMode: int) -> bool:
        return self._set(self._cam.setFlashState(flashMode & 0xFF),
                         "Flash state set successfully", "Set flash state failed")

    @pyqtSlot(result=bool)
    def getStreamMode(self) -> bool:
        ok, v = self._cam.getStreamMode()
        if ok:
            self.streamModeValue.emit(int(v["mode"]), bool(v["autofunclock"]))
            return True
        return False

    @pyqtSlot(int, bool, result=bool)
    def setStreamMode(self, streamMode: int, autoFunctionLock: bool) -> bool:
        return self._set(self._cam.setStreamMode(streamMode & 0xFF, autoFunctionLock),
                         "Stream mode set successfully", "Set stream mode failed")

    # ---- Default / Serial / Firmware -----------------------------------

    @pyqtSlot(result=bool)
    def setToDefault(self) -> bool:
        return self._set(self._cam.restoreDefault(),
                         "Device reset to defaults successfully", "Reset to defaults failed")

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
