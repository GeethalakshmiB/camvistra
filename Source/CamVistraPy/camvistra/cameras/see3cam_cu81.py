"""See3CAM_CU81 controller.

Port of CamVistra/Model/src/See3CAM_CU81_Model.cpp and
CamVistra/Controller/src/See3CAM_CU81_Controller.cpp.
QML: context property ``see3camcu81Controller``, type ``See3CAMCU81``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


def _int32(value: int) -> int:
    """static_cast<int>(uint32_t) - two's complement wrap."""
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value & 0x80000000 else value


class See3CAM_CU81_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU81

    class CameraMode_CU81(enum.IntEnum):
        HDR_MODE = 0x01
        LINEAR_MODE = 0x02
    Q_ENUM(CameraMode_CU81)

    class SpecialEffect_CU81(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(SpecialEffect_CU81)

    class ROIAutoExpMode_CU81(enum.IntEnum):
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(ROIAutoExpMode_CU81)

    class FlipMode_CU81(enum.IntEnum):
        BOTH_DISABLE = 0x00
        HORZ_ONLY = 0x01
        VERT_ONLY = 0x02
        BOTH_ENABLE = 0x03
    Q_ENUM(FlipMode_CU81)

    class AntiFlickerMode_CU81(enum.IntEnum):
        AntiFlickerAuto = 0x00
        AntiFlicker50Hz = 0x01
        AntiFlicker60Hz = 0x02
        AntiFlickerDisable = 0x03
    Q_ENUM(AntiFlickerMode_CU81)

    class FaceDetection_CU81(enum.IntEnum):
        FaceRectEnable = 0x01
        FaceRectDisable = 0x00
        EmbedDataEnable = 0x01
        EmbedDataDisable = 0x00
        OverlayRectEnable = 0x01
        OverlayRectDisable = 0x00
    Q_ENUM(FaceDetection_CU81)

    class SaveConfiguration_CU81(enum.IntEnum):
        DEFAULT = 0x00
        USER_DEFINED = 0x01
    Q_ENUM(SaveConfiguration_CU81)

    cameraModeReceived = pyqtSignal(int, arguments=['cameraMode'])
    effectModeReceived = pyqtSignal(int, arguments=['effectMode'])
    denoiseValueReceived = pyqtSignal(int, arguments=['denoiseValue'])
    roiAutoExpModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    autoExposureReceived = pyqtSignal("uint", arguments=['autoExposure'])
    exposureCompReceived = pyqtSignal("uint", arguments=['expComp'])
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    frameRateReceived = pyqtSignal(int, arguments=['frameRate'])
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    faceDetectModeReceived = pyqtSignal(int, int, int, arguments=['mode', 'embedData', 'overlayRect'])
    autoWhiteBalanceReceived = pyqtSignal(int, arguments=['awbValue'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # ------------------------------------------------------------------
    def _get_value(self, getter, signal, conv=int) -> int:
        ok, value = getter()
        if ok:
            signal.emit(conv(value))
            return 1
        return 0

    def _set_int(self, ok, success: str, failure: str) -> int:
        self.statusChanged.emit(success if ok else failure)
        return 1 if ok else 0

    # ---- Camera Mode ---------------------------------------------------

    @pyqtSlot(result=int)
    def getCameraMode(self) -> int:
        return self._get_value(self._cam.getCameraMode, self.cameraModeReceived)

    @pyqtSlot(int, result=int)
    def setCameraMode(self, cameraMode: int) -> int:
        return self._set_int(self._cam.setCameraMode(cameraMode),
                             "Camera mode set successfully", "Set camera mode failed")

    # ---- Effect / Denoise ----------------------------------------------

    @pyqtSlot(result=int)
    def getEffect(self) -> int:
        return self._get_value(self._cam.getEffectMode, self.effectModeReceived)

    @pyqtSlot(int, result=int)
    def setEffect(self, effectMode: int) -> int:
        return self._set_int(self._cam.setEffectMode(effectMode),
                             "Effect mode set successfully", "Set effect mode failed")

    @pyqtSlot(result=int)
    def getDenoise(self) -> int:
        return self._get_value(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoise(self, denoiseValue: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(denoiseValue & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto Exposure ROI ---------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROI(self) -> int:
        ok, result = self._cam.getAutoExpROIMode()
        if ok:
            self.roiAutoExpModeReceived.emit(int(result["mode"]), int(result["wnsize"]))
            return 1
        return 0

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoExpROI(self, roiMode: int, vidW: int, vidH: int, xCord: int, yCord: int, winSize: int) -> int:
        return self._set_int(
            self._cam.setROIAutoExposure(roiMode, vidW & 0xFFFFFFFF, vidH & 0xFFFFFFFF,
                                         xCord & 0xFFFFFFFF, yCord & 0xFFFFFFFF, winSize & 0xFF),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    @pyqtSlot(result=int)
    def getAutoExposure(self) -> int:
        return self._get_value(self._cam.getAutoExposure, self.autoExposureReceived)

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        return self._get_value(self._cam.getExposureCompensation, self.exposureCompReceived)

    @pyqtSlot("uint", result=int)
    def setExposureCompensation(self, expCompValue: int) -> int:
        return self._set_int(self._cam.setExposureCompensation(expCompValue),
                             "Exposure compensation set successfully", "Set exposure compensation failed")

    # ---- Burst / QFactor / FrameRate -----------------------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_value(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    @pyqtSlot(result=int)
    def getQFactor(self) -> int:
        return self._get_value(self._cam.getQFactor, self.qFactorReceived)

    @pyqtSlot(int, result=int)
    def setQFactor(self, qFactor: int) -> int:
        return self._set_int(self._cam.setQFactor(qFactor & 0xFF),
                             "Q factor set successfully", "Set Q factor failed")

    @pyqtSlot(result=int)
    def getFrameRateCtrlValue(self) -> int:
        return self._get_value(self._cam.getFrameRateCtrlValue, self.frameRateReceived)

    @pyqtSlot(int, result=int)
    def setFrameRateCtrlValue(self, frameRate: int) -> int:
        return self._set_int(self._cam.setFrameRateCtrlValue(frameRate & 0xFF),
                             "Frame rate set successfully", "Set frame rate failed")

    # ---- Flip / AntiFlicker --------------------------------------------

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get_value(self._cam.getFlipMode, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setFlipMode(horzFlip, vertFlip),
                             "Flip mode set successfully", "Set flip mode failed")

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_value(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Face Detection ------------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetectMode(self) -> int:
        ok, result = self._cam.getFaceDetectMode()
        if ok:
            self.faceDetectModeReceived.emit(int(result["state"]), int(result["embedData"]),
                                             int(result["overlayrect"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetectRect(self, enable: bool, embedData: bool, overlayRect: bool) -> int:
        return self._set_int(self._cam.setFaceDetectionRect(enable, embedData, overlayRect),
                             "Face detection rect set successfully", "Set face detection rect failed")

    # ---- White Balance -------------------------------------------------

    @pyqtSlot(result=int)
    def getAutoWhiteBalance(self) -> int:
        return self._get_value(self._cam.getAutoWhiteBalance, self.autoWhiteBalanceReceived, _int32)

    # ---- Save / Default / Serial / Firmware ----------------------------

    @pyqtSlot(int, result=int)
    def saveConfiguration(self, configType: int) -> int:
        return self._set_int(self._cam.saveConfiguration(configType),
                             "Configuration saved successfully", "Save configuration failed")

    @pyqtSlot(result=int)
    def setToDefault(self) -> int:
        return self._set_int(self._cam.setToDefault(),
                             "Device reset to defaults successfully", "Reset to defaults failed")

    @pyqtSlot(result=int)
    def getSerialNumber(self) -> int:
        ok, uniqueID = self._cam.getCameraUniqueID64()
        if ok:
            self.serialNumberReceived.emit(uniqueID)
            return 1
        self.statusChanged.emit("Read serial number failed")
        return 0

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, firmwareVersion = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(firmwareVersion)
            return 1
        self.statusChanged.emit("Read firmware version failed")
        return 0
