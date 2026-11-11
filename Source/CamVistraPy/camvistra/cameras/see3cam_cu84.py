"""See3CAM_CU84 controller.

Port of CamVistra/Model/src/See3CAM_CU84_Model.cpp and
CamVistra/Controller/src/See3CAM_CU84_Controller.cpp.
QML: context property ``see3camcu84Controller``, type ``See3CAMCU84``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU84_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU84

    class SpecialEffectCU84(enum.IntEnum):
        EFFECT_NORMAL = 0x01
        EFFECT_BLACK_WHITE = 0x04
        EFFECT_GREYSCALE = 0x07
        EFFECT_NEGATIVE = 0x08
        EFFECT_SKETCH = 0x10
    Q_ENUM(SpecialEffectCU84)

    class ROIAutoExpModeCU84(enum.IntEnum):
        FULL_ROI = 0x01
        MANUAL_ROI = 0x02
    Q_ENUM(ROIAutoExpModeCU84)

    class FlipModeCU84(enum.IntEnum):
        BOTH_DISABLE = 0x00
        HORZ_ONLY = 0x01
        VERT_ONLY = 0x02
        BOTH_ENABLE = 0x03
    Q_ENUM(FlipModeCU84)

    class AntiFlickerCU84(enum.IntEnum):
        MODE_AUTO = 0x00
        MODE_50Hz = 0x01
        MODE_60Hz = 0x02
        MODE_DISABLE = 0x03
    Q_ENUM(AntiFlickerCU84)

    class StreamModeCU84(enum.IntEnum):
        MASTER_MODE = 0x00
        TRIGGER_MODE = 0x01
    Q_ENUM(StreamModeCU84)

    class FlashModeCU84(enum.IntEnum):
        STROBE_OFF = 0x00
        STROBE_ON = 0x01
    Q_ENUM(FlashModeCU84)

    class FaceDetectCU84(enum.IntEnum):
        FaceRectEnable = 0x01
        FaceRectDisable = 0x00
        OverlayRectEnable = 0x01
        OverlayRectDisable = 0x00
        EmbedDataEnable = 0x01
        EmbedDataDisable = 0x00
    Q_ENUM(FaceDetectCU84)

    specialEffectReceived = pyqtSignal(int, arguments=['effect'])
    denoiseValueReceived = pyqtSignal(int, arguments=['denoiseValue'])
    roiAutoExpModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    exposureCompReceived = pyqtSignal("uint", arguments=['expComp'])
    frameRateReceived = pyqtSignal(int, arguments=['frameRate'])
    minimumFramesReceived = pyqtSignal(int, arguments=['minimumFps'])
    maximumFramesReceived = pyqtSignal(int, arguments=['maximumFps'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    streamModeReceived = pyqtSignal(int, arguments=['streamMode'])
    flashModeReceived = pyqtSignal(int, arguments=['flashMode'])
    faceDetectModeReceived = pyqtSignal(int, int, int, arguments=['mode', 'overlayRect', 'embedData'])
    qFactorReceived = pyqtSignal(int, arguments=['qFactor'])
    motionDetectSensitivityReceived = pyqtSignal(int, int, int, arguments=['current', 'minimum', 'maximum'])
    motionDetectZoneMaskReceived = pyqtSignal(int, int, int, int, int, int, int, int, int, arguments=['zone0', 'zone1', 'zone2', 'zone3', 'zone4', 'zone5', 'zone6', 'zone7', 'zone8'])
    exposureReceived = pyqtSignal(int, "uint", arguments=['mode', 'value'])
    wbProModeReceived = pyqtSignal(int, "uint", "uint", "uint", "uint", "uint", arguments=['proMode', 'rGain', 'gGain', 'bGain', 'gainMin', 'gainMax'])
    rgbGainReceived = pyqtSignal("uint", "uint", "uint", arguments=['rGain', 'gGain', 'bGain'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    # Model-only signal: the C++ Controller does not forward it to QML.
    indicateExposureValueRangeFailure = pyqtSignal(str, str)

    # ------------------------------------------------------------------
    def _set_int(self, ok, success: str, failure: str) -> int:
        self.statusChanged.emit(success if ok else failure)
        return 1 if ok else 0

    def _get_value(self, getter, signal) -> int:
        ok, value = getter()
        if ok:
            signal.emit(int(value))
            return 1
        return 0

    # ---- Special effects ------------------------------------------------

    @pyqtSlot(result=int)
    def getSpecialEffect(self) -> int:
        return self._get_value(self._cam.getSpecialEffect, self.specialEffectReceived)

    @pyqtSlot(int, result=int)
    def setSpecialEffect(self, effect: int) -> int:
        return self._set_int(self._cam.setSpecialEffect(effect & 0xFF),
                             "Special effect set successfully", "Set special effect failed")

    # ---- Denoise --------------------------------------------------------

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get_value(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, denoiseVal: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(denoiseVal & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    # ---- Auto-exposure ROI ---------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROIMode(self) -> int:
        ok, v = self._cam.getAutoExpROIMode()
        if ok:
            self.roiAutoExpModeReceived.emit(int(v["mode"]), int(v["wnsize"]))
            return 1
        return 0

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoExpROIMode(self, roiMode: int, vidW: int, vidH: int,
                          xCord: int, yCord: int, winSize: int) -> int:
        return self._set_int(
            self._cam.setAutoExpROIMode(roiMode & 0xFF,
                                        vidW & 0xFFFFFFFF, vidH & 0xFFFFFFFF,
                                        xCord & 0xFFFFFFFF, yCord & 0xFFFFFFFF,
                                        winSize & 0xFF),
            "Auto exposure ROI set successfully", "Set auto exposure ROI failed")

    # ---- Burst length ---------------------------------------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_value(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    # ---- Flip / orientation ---------------------------------------------

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get_value(self._cam.getFlipMode, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setFlipMode(bool(horzFlip), bool(vertFlip)),
                             "Flip mode set successfully", "Set flip mode failed")

    # ---- Exposure compensation ------------------------------------------

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        ok, value = self._cam.getExposureCompensation()
        if ok:
            self.exposureCompReceived.emit(value)
            return 1
        return 0

    @pyqtSlot("uint", result=int)
    def setExposureCompensation(self, expCompValue: int) -> int:
        if self._cam.setExposureCompensation(expCompValue & 0xFFFFFFFF):
            self.statusChanged.emit("Exposure compensation set successfully")
            return 1
        self.indicateExposureValueRangeFailure.emit("Exposure Compensation",
                                                    "Value out of range or set failed")
        self.statusChanged.emit("Set exposure compensation failed")
        return 0

    # ---- Frame rate control ---------------------------------------------

    @pyqtSlot(result=int)
    def getFrameRateCtrl(self) -> int:
        ok, v = self._cam.getFrameRateCtrl()
        if ok:
            self.frameRateReceived.emit(int(v["ctrl_value"]))
            self.minimumFramesReceived.emit(int(v["min_fps"]))
            self.maximumFramesReceived.emit(int(v["max_fps"]))
            return 1
        return 0

    @pyqtSlot(int, result=int)
    def setFrameRateCtrl(self, frameRate: int) -> int:
        return self._set_int(self._cam.setFrameRateCtrl(frameRate & 0xFF),
                             "Frame rate set successfully", "Set frame rate failed")

    # ---- Anti-flicker ---------------------------------------------------

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_value(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode & 0xFF),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Stream mode ----------------------------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get_value(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, streamMode: int) -> int:
        return self._set_int(self._cam.setStreamMode(streamMode & 0xFF),
                             "Stream mode set successfully", "Set stream mode failed")

    # ---- Flash mode -----------------------------------------------------

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get_value(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, flashMode: int) -> int:
        return self._set_int(self._cam.setFlashMode(flashMode & 0xFF),
                             "Flash mode set successfully", "Set flash mode failed")

    # ---- Face detection -------------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetection(self) -> int:
        ok, v = self._cam.getFaceDetection()
        if ok:
            self.faceDetectModeReceived.emit(int(v["option"]), int(v["overlayrect"]), int(v["embedData"]))
            return 1
        return 0

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetection(self, enableRect: bool, overlayRect: bool, embedData: bool) -> int:
        return self._set_int(self._cam.setFaceDetection(bool(enableRect), bool(overlayRect), bool(embedData)),
                             "Face detection set successfully", "Set face detection failed")

    # ---- Q-factor -------------------------------------------------------

    @pyqtSlot(result=int)
    def getQFactor(self) -> int:
        return self._get_value(self._cam.getQFactor, self.qFactorReceived)

    @pyqtSlot(int, result=int)
    def setQFactor(self, qFactor: int) -> int:
        return self._set_int(self._cam.setQFactor(qFactor & 0xFF),
                             "Q factor set successfully", "Set Q factor failed")

    # ---- Motion detection (extended) ------------------------------------

    @pyqtSlot(result=int)
    def getMotionDetectSensitivity(self) -> int:
        ok, v = self._cam.getMotionDetectSensitivity()
        if ok:
            self.motionDetectSensitivityReceived.emit(int(v["current"]), int(v["minimum"]), int(v["maximum"]))
            return 1
        return 0

    @pyqtSlot(int, result=int)
    def setMotionDetectSensitivity(self, sensitivity: int) -> int:
        return self._set_int(self._cam.setMotionDetectSensitivity(sensitivity & 0xFFFF),
                             "Motion detect sensitivity set successfully",
                             "Set motion detect sensitivity failed")

    @pyqtSlot(result=int)
    def getMotionDetectZoneMask(self) -> int:
        ok, v = self._cam.getMotionDetectZoneMask()
        if ok:
            zone = v["zone"]
            self.motionDetectZoneMaskReceived.emit(*(int(zone[i]) for i in range(9)))
            return 1
        return 0

    # ---- Exposure (extended) --------------------------------------------

    @pyqtSlot(result=int)
    def getExposure(self) -> int:
        ok, v = self._cam.getExposure()
        if ok:
            self.exposureReceived.emit(int(v["mode"]), v["value"])
            return 1
        return 0

    @pyqtSlot(int, "uint", result=int)
    def setExposure(self, mode: int, value: int) -> int:
        return self._set_int(self._cam.setExposure(mode & 0xFF, value & 0xFFFFFFFF),
                             "Exposure set successfully", "Set exposure failed")

    # ---- White-balance pro mode (extended) ------------------------------

    @pyqtSlot(result=int)
    def getWBProMode(self) -> int:
        ok, v = self._cam.getWBProMode()
        if ok:
            self.wbProModeReceived.emit(int(v["proMode"]), v["rGain"], v["gGain"], v["bGain"],
                                        v["gain_min"], v["gain_max"])
            return 1
        return 0

    @pyqtSlot(int, result=int)
    def setWBProMode(self, proMode: int) -> int:
        return self._set_int(self._cam.setWBProMode(proMode & 0xFF),
                             "White balance pro mode set successfully", "Set white balance pro mode failed")

    # ---- RGB gain (extended) --------------------------------------------

    @pyqtSlot(result=int)
    def getRGBGain(self) -> int:
        ok, v = self._cam.getRGBGain()
        if ok:
            self.rgbGainReceived.emit(v["rGain"], v["gGain"], v["bGain"])
            return 1
        return 0

    @pyqtSlot(int, "uint", "uint", "uint", result=int)
    def setRGBGain(self, setMode: int, rGain: int, gGain: int, bGain: int) -> int:
        return self._set_int(self._cam.setRGBGain(setMode & 0xFF, rGain & 0xFFFFFFFF,
                                                  gGain & 0xFFFFFFFF, bGain & 0xFFFFFFFF),
                             "RGB gain set successfully", "Set RGB gain failed")

    # ---- Restore defaults / serial number / firmware --------------------

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
