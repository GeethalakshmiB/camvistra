"""See3CAM_CU58 controller.

Port of CamVistra/Model/src/See3CAM_CU58_Model.cpp and
CamVistra/Controller/src/See3CAM_CU58_Controller.cpp.
QML: context property ``see3camcu58Controller``, type ``See3CAMCU58``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU58_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU58

    class SceneModeCU58(enum.IntEnum):
        SCENE_NORMAL = 0x01
        SCENE_DOCUMENT = 0x0C
    Q_ENUM(SceneModeCU58)

    class SpecialEffectCU58(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(SpecialEffectCU58)

    class AfModeCU58(enum.IntEnum):
        Continuous = 0x01
        OneShot = 0x02
        AfDisabled = 0x03
    Q_ENUM(AfModeCU58)

    class AfRectCU58(enum.IntEnum):
        Enable = 0x01
        Disable = 0x00
    Q_ENUM(AfRectCU58)

    class FaceDetectionCU58(enum.IntEnum):
        # Duplicate values become enum aliases, like the C++ enum.
        FDEnable = 0x01
        FDDisable = 0x00
        RectEnable = 0x01
        RectDisable = 0x00
        EmbedDataEnable = 0x01
        EmbedDataDisable = 0x00
    Q_ENUM(FaceDetectionCU58)

    class FlashModeCU58(enum.IntEnum):
        DISABLE = 0x00
        STROBE = 0x01
        TORCH = 0x02
    Q_ENUM(FlashModeCU58)

    class ROIAfModeCU58(enum.IntEnum):
        AF_Centered = 0x01
        AF_Manual = 0x02
        AF_Disabled = 0x03
    Q_ENUM(ROIAfModeCU58)

    class ROIAutoExpModeCU58(enum.IntEnum):
        AE_Face = 0x00
        AE_Full = 0x01
        AE_Manual = 0x02
        AE_Disabled = 0x03
    Q_ENUM(ROIAutoExpModeCU58)

    class HDRModeCU58(enum.IntEnum):
        HdrOff = 0x01
        HdrAuto = 0x02
        HdrManual = 0x03
    Q_ENUM(HDRModeCU58)

    class FlickerModeCU58(enum.IntEnum):
        MODE_AUTO = 0x03
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_DISABLE = 0x00
    Q_ENUM(FlickerModeCU58)

    class FlipModeCU58(enum.IntEnum):
        BOTH_DISABLE = 0x00
        HORZ_ONLY = 0x01
        VERT_ONLY = 0x02
        BOTH_ENABLE = 0x03
    Q_ENUM(FlipModeCU58)

    # Effect / Denoise
    effectModeReceived = pyqtSignal(int, arguments=['effectMode'])
    denoiseValueReceived = pyqtSignal(int, arguments=['denoiseValue'])
    # Auto Exposure
    roiAutoExpModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    exposureCompReceived = pyqtSignal("uint", arguments=['expComp'])
    # Burst / QFactor / FrameRate
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    frameRateReceived = pyqtSignal(int, arguments=['frameRate'])
    # Flip / AntiFlicker
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    # Face Detection / Flash
    faceDetectModeReceived = pyqtSignal(int, int, int, arguments=['mode', 'embedData', 'overlayRect'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
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

    # ---- Effect / Denoise ----------------------------------------------

    @pyqtSlot(result=int)
    def getEffectMode(self) -> int:
        return self._get_u8(self._cam.getEffectMode, self.effectModeReceived)

    @pyqtSlot(int, result=int)
    def setEffectMode(self, effectMode: int) -> int:
        return self._set_int(self._cam.setEffectMode(effectMode),
                             "Effect mode set successfully", "Set effect mode failed")

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get_u8(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, denoiseVal: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(denoiseVal & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto Exposure ---------------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROI(self) -> int:
        ok, v = self._cam.getAutoExpROI()
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

    # ---- Burst / QFactor / FrameRate -------------------------------------

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
        return self._get_u8(self._cam.getFrameRateCtrlValue, self.frameRateReceived)

    @pyqtSlot(int, result=int)
    def setFrameRateCtrlValue(self, frameRate: int) -> int:
        return self._set_int(self._cam.setFrameRateCtrlValue(frameRate & 0xFF),
                             "Frame rate set successfully", "Set frame rate failed")

    # ---- Flip / AntiFlicker ----------------------------------------------

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get_u8(self._cam.getFlipMode, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setFlipMode(horzFlip, vertFlip),
                             "Flip mode set successfully", "Set flip mode failed")

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_u8(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Face Detection / Flash ------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetectMode(self) -> int:
        ok, v = self._cam.getFaceDetectMode()
        if ok:
            self.faceDetectModeReceived.emit(int(v["mode"]), int(v["embedData"]), int(v["overlayRect"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetectRect(self, enable: bool, embedData: bool, overlayRect: bool) -> int:
        return self._set_int(self._cam.setFaceDetectRect(enable, embedData, overlayRect),
                             "Face detection rect set successfully", "Set face detection rect failed")

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get_u8(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        return self._set_int(self._cam.setFlashMode(flashMode),
                             "Flash mode set successfully", "Set flash mode failed")

    # ---- Default / Serial / Firmware -------------------------------------

    @pyqtSlot(result=int)
    def setToDefault(self) -> int:
        return self._set_int(self._cam.setToDefault(),
                             "Device reset to defaults successfully", "Reset to defaults failed")

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, serial = self._cam.get64BitSerialNumber()
        if ok:
            # snprintf("%016llx"): 16-char lower-case hex
            self.serialNumberReceived.emit("%016x" % (int(serial) & 0xFFFFFFFFFFFFFFFF))
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
