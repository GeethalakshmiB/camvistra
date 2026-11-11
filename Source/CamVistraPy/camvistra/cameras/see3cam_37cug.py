"""See3CAM_37CUG controller.

Port of CamVistra/Model/src/See3CAM_37CUG_Model.cpp and
CamVistra/Controller/src/See3CAM_37CUG_Controller.cpp.
QML: context property ``see3cam37cugController``, type ``See3CAM37CUG``.

Unlike most See3CAM models, the 37CUG model emits no status messages: the
setters simply return the SDK result as 1/0.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk

_U8 = 0xFF
_U16 = 0xFFFF


class See3CAM_37CUG_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_37CUG

    class Value(enum.IntEnum):
        # Duplicate values become enum aliases, like the C++ enum.
        MASTER = 1
        TRIGGER_EXPOSURE = 2
        AUTO_GAIN = 0
        MANUAL_GAIN = 1
        CONTINUOUS_GAIN = 0
        SINGLE_GAIN = 1
        TRIGGER_GAIN = 2
        AUTO_EXPOSURE = 0
        MANUAL_EXPOSURE = 1
        CONTINUOUS_EXPOSURE = 0
        SINGLE_EXPOSURE_TRIGGER = 1
        FLICKER_50_HZ = 0
        FLICKER_60_HZ = 1
        FLICKER_DISABLE = 2
        HDR_ADAPTIVE = 0
        HDR_DAY = 1
        HDR_NIGHT = 2
        DISABLE = 0
        ENABLE = 1
    Q_ENUM(Value)

    cameraModeReceived = pyqtSignal(int, arguments=['mode'])
    orientationReceived = pyqtSignal(int, arguments=['orientation'])
    gainPropertiesReceived = pyqtSignal(int, int, int, int, int, int, arguments=['mode', 'feature', 'minimum', 'maximum', 'current', 'step'])
    strobeModeReceived = pyqtSignal(int, arguments=['mode'])
    burstLengthReceived = pyqtSignal(int, arguments=['length'])
    exposurePropertiesReceived = pyqtSignal(int, int, "uint", "uint", "uint", arguments=['mode', 'feature', 'seconds', 'milliSeconds', 'microSeconds'])
    targetBrightnessReceived = pyqtSignal("uint", "uint", "uint", "uint", arguments=['minimum', 'maximum', 'step', 'current'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['mode'])
    statisticsReceived = pyqtSignal("uint", "uint", "uint", int, arguments=['seconds', 'milliSeconds', 'microSeconds', 'gain'])
    temperatureReceived = pyqtSignal(float, arguments=['temperature'])
    fastAutoExposureReceived = pyqtSignal(int, arguments=['mode'])
    selfTriggerReceived = pyqtSignal(int,
                                     int, int, int, int,
                                     int, int, int, int,
                                     "uint", int, int,
                                     "uint", "uint",
                                     int, int,
                                     "uint", "uint",
                                     int, int, int, int,
                                     int, int, int, int, arguments=['mode', 'horizontalCropSize', 'horizontalCropMinimum', 'horizontalCropMaximum', 'horizontalCropStep', 'verticalCropSize', 'verticalCropMinimum', 'verticalCropMaximum', 'verticalCropStep', 'exposure', 'highLevel', 'lowLevel', 'highCount', 'lowCount', 'sensingMode', 'forceMode', 'highDetectedPixels', 'lowDetectedPixels', 'sensingGain', 'sensingGainMinimum', 'sensingGainMaximum', 'sensingGainStep', 'capturingGain', 'capturingGainMinimum', 'capturingGainMaximum', 'capturingGainStep'])
    exposureCompensationReceived = pyqtSignal("uint", "uint", "uint", arguments=['seconds', 'milliSeconds', 'microSeconds'])
    faeTargetBrightnessReceived = pyqtSignal("uint", "uint", "uint", "uint", arguments=['minimum', 'maximum', 'step', 'current'])
    faeExecutionFramesReceived = pyqtSignal(int, arguments=['frames'])
    ispFirmwareVersionReceived = pyqtSignal(str, arguments=['version'])
    # ------------------------------------------------------------------
    # Initialisation: the 37CUG model returns the SDK result of setHidFd
    # (the other models always return 1).
    # ------------------------------------------------------------------

    @pyqtSlot(int, result=int)
    def initialize(self, fd: int) -> int:
        return 1 if self._cam.setHidFd(fd) else 0

    # ------------------------------------------------------------------
    def _get_u8(self, getter, signal) -> int:
        ok, value = getter()
        if not ok:
            return 0
        signal.emit(int(value))
        return 1

    @staticmethod
    def _ret(ok) -> int:
        return 1 if ok else 0

    # ---- Camera mode / Orientation -------------------------------------

    @pyqtSlot(result=int)
    def getCameraMode(self) -> int:
        return self._get_u8(self._cam.getCameraMode, self.cameraModeReceived)

    @pyqtSlot(int, result=int)
    def setCameraMode(self, mode: int) -> int:
        return self._ret(self._cam.setCameraMode(mode))

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get_u8(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, horizontal: bool, vertical: bool) -> int:
        return self._ret(self._cam.setOrientation(horizontal, vertical))

    # ---- Gain -----------------------------------------------------------

    @pyqtSlot(result=int)
    def getGainMode(self) -> int:
        ok, v = self._cam.getGainMode()
        if not ok:
            return 0
        self.gainPropertiesReceived.emit(v["mode"], v["feature"], v["minimum"],
                                         v["maximum"], v["current"], v["step"])
        return 1

    @pyqtSlot(int, int, int, result=int)
    def setGainMode(self, mode: int, feature: int, gain: int) -> int:
        return self._ret(self._cam.setGainMode(mode, feature, gain & _U16))

    # ---- Strobe / Burst -------------------------------------------------

    @pyqtSlot(result=int)
    def getStrobeMode(self) -> int:
        return self._get_u8(self._cam.getStrobeMode, self.strobeModeReceived)

    @pyqtSlot(int, result=int)
    def setStrobeMode(self, mode: int) -> int:
        return self._ret(self._cam.setStrobeMode(mode & _U8))

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_u8(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, length: int) -> int:
        return self._ret(self._cam.setBurstLength(length & _U8))

    # ---- Exposure / Target brightness / Anti-flicker --------------------

    @pyqtSlot(result=int)
    def getExposureMode(self) -> int:
        ok, v = self._cam.getExposureMode()
        if not ok:
            return 0
        self.exposurePropertiesReceived.emit(v["mode"], v["feature"], v["seconds"],
                                             v["milliSeconds"], v["microSeconds"])
        return 1

    @pyqtSlot(int, int, "uint", "uint", "uint", result=int)
    def setExposureMode(self, mode: int, feature: int, seconds: int,
                        milliSeconds: int, microSeconds: int) -> int:
        return self._ret(self._cam.setExposureMode(mode, feature, seconds, milliSeconds, microSeconds))

    @pyqtSlot(result=int)
    def getTargetBrightness(self) -> int:
        ok, v = self._cam.getTargetBrightness()
        if not ok:
            return 0
        self.targetBrightnessReceived.emit(v["minimum"], v["maximum"], v["step"], v["current"])
        return 1

    @pyqtSlot(int, result=int)
    def setTargetBrightness(self, brightness: int) -> int:
        return self._ret(self._cam.setTargetBrightness(brightness & _U16))

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_u8(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, mode: int) -> int:
        return self._ret(self._cam.setAntiFlickerMode(mode))

    # ---- Statistics / Temperature ---------------------------------------

    @pyqtSlot(result=int)
    def readStatistics(self) -> int:
        ok, seconds, milliSeconds, microSeconds, gain = self._cam.readStatistics()
        if not ok:
            return 0
        self.statisticsReceived.emit(seconds, milliSeconds, microSeconds, gain)
        return 1

    @pyqtSlot(result=int)
    def readTemperature(self) -> int:
        ok, value = self._cam.readTemperature()
        if not ok:
            return 0
        self.temperatureReceived.emit(float(value))
        return 1

    # ---- Fast auto exposure ---------------------------------------------

    @pyqtSlot(result=int)
    def getFastAutoExposure(self) -> int:
        return self._get_u8(self._cam.getFastAutoExposure, self.fastAutoExposureReceived)

    @pyqtSlot(int, result=int)
    def setFastAutoExposure(self, mode: int) -> int:
        return self._ret(self._cam.setFastAutoExposure(mode & _U8))

    # ---- Self trigger -----------------------------------------------------

    @pyqtSlot(result=int)
    def getSelfTrigger(self) -> int:
        ok, v = self._cam.getSelfTrigger()
        if not ok:
            return 0
        h, vc = v["horizontalCrop"], v["verticalCrop"]
        sg, cg = v["sensingGain"], v["capturingGain"]
        self.selfTriggerReceived.emit(
            v["mode"],
            h["size"], h["minimum"], h["maximum"], h["step"],
            vc["size"], vc["minimum"], vc["maximum"], vc["step"],
            v["exposure"], v["highLevel"], v["lowLevel"],
            v["highCount"], v["lowCount"],
            v["sensingMode"], v["forceMode"],
            v["highDetectedPixels"], v["lowDetectedPixels"],
            sg["gain"], sg["minimum"], sg["maximum"], sg["step"],
            cg["gain"], cg["minimum"], cg["maximum"], cg["step"])
        return 1

    @pyqtSlot(int, int, int, int, int, int, int, "uint", int, int, "uint", "uint",
              int, int, "uint", "uint", int, int, result=int)
    def setSelfTrigger(self, mode: int, videoWidth: int, videoHeight: int,
                       hCropPos: int, vCropPos: int, hCropSize: int, vCropSize: int,
                       exposure: int, highLevel: int, lowLevel: int,
                       highCount: int, lowCount: int,
                       sensingMode: int, forceMode: int,
                       highDetectedPixels: int, lowDetectedPixels: int,
                       sensingGain: int, capturingGain: int) -> int:
        return self._ret(self._cam.setSelfTrigger(
            mode & _U8,
            videoWidth & _U16, videoHeight & _U16,
            hCropPos & _U16, vCropPos & _U16,
            hCropSize & _U16, vCropSize & _U16,
            exposure, highLevel & _U16, lowLevel & _U16,
            highCount, lowCount,
            sensingMode & _U8, forceMode & _U8,
            highDetectedPixels, lowDetectedPixels,
            sensingGain & _U16, capturingGain & _U16))

    # ---- Exposure compensation -------------------------------------------

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        ok, seconds, milliSeconds, microSeconds = self._cam.getExposureCompensation()
        if not ok:
            return 0
        self.exposureCompensationReceived.emit(seconds, milliSeconds, microSeconds)
        return 1

    @pyqtSlot("uint", "uint", "uint", result=int)
    def setExposureCompensation(self, seconds: int, milliSeconds: int, microSeconds: int) -> int:
        return self._ret(self._cam.setExposureCompensation(seconds, milliSeconds, microSeconds))

    # ---- Fast AE target brightness / execution frames --------------------

    @pyqtSlot(result=int)
    def getFAETargetBrightness(self) -> int:
        ok, v = self._cam.getFAETargetBrightness()
        if not ok:
            return 0
        self.faeTargetBrightnessReceived.emit(v["minimum"], v["maximum"], v["step"], v["current"])
        return 1

    @pyqtSlot(int, result=int)
    def setFAETargetBrightness(self, brightness: int) -> int:
        return self._ret(self._cam.setFAETargetBrightness(brightness & _U16))

    @pyqtSlot(result=int)
    def getFAEExecutionFrames(self) -> int:
        return self._get_u8(self._cam.getFAEExecutionFrames, self.faeExecutionFramesReceived)

    @pyqtSlot(int, result=int)
    def setFAEExecutionFrames(self, frames: int) -> int:
        return self._ret(self._cam.setFAEExecutionFrames(frames & _U8))

    # ---- Default / ISP firmware -------------------------------------------

    @pyqtSlot(result=int)
    def setToDefaultValues(self) -> int:
        return self._ret(self._cam.setToDefaultValues())

    @pyqtSlot(result=int)
    def readISPFirmwareVersion(self) -> int:
        ok, v = self._cam.readISPFirmwareVersion()
        if not ok:
            return 0
        self.ispFirmwareVersionReceived.emit(
            "%d.%d.%d.%d" % (v["major"], v["minor"], v["patch"], v["build"]))
        return 1
