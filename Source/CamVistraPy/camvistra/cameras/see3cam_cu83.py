"""See3CAM_CU83 controller.

Port of CamVistra/Model/src/See3CAM_CU83_Model.cpp and
CamVistra/Controller/src/See3CAM_CU83_Controller.cpp.
QML: context property ``see3camcu83Controller``, type ``See3CAMCU83``.

Unlike most Models, the CU83 Model emits no status messages: setters return
the SDK result (1/0) directly and getters emit only on success.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU83_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU83

    class Values(enum.IntEnum):
        EFFECT_NORMAL = 1
        EFFECT_BLACK_WHITE = 4
        EFFECT_GREYSCALE = 7
        EFFECT_NEGATIVE = 8
        EFFECT_SKETCH = 16
        FULL_ROI = 1
        MANUAL_ROI = 2
        MODE_AUTO = 0
        MODE_50Hz = 1
        MODE_60Hz = 2
        MODE_DISABLE = 3
        DISABLE = 0
        ENABLE = 1
        MASTER_MODE = 0
        TRIGGER_MODE = 1
        STROBE_OFF = 0
        STROBE_ON = 1
    Q_ENUM(Values)

    specialModeReceived = pyqtSignal(int, arguments=['mode'])
    denoiseValueReceived = pyqtSignal(int, arguments=['value'])
    roiAutoExpReceived = pyqtSignal(int, int, arguments=['mode', 'windowSize'])
    orientationReceived = pyqtSignal(int, arguments=['orientation'])
    exposureCompensationReceived = pyqtSignal("uint", arguments=['exposure'])
    frameRateReceived = pyqtSignal(int, int, int, arguments=['value', 'minimum', 'maximum'])
    burstLengthReceived = pyqtSignal(int, arguments=['length'])
    antiFlickerReceived = pyqtSignal(int, arguments=['mode'])
    wakeOnMotionReceived = pyqtSignal(int, arguments=['status'])
    faceDetectionReceived = pyqtSignal(int, int, int, arguments=['enabled', 'overlay', 'embeddedData'])
    streamModeReceived = pyqtSignal(int, arguments=['mode'])
    flashModeReceived = pyqtSignal(int, arguments=['mode'])
    # ------------------------------------------------------------------
    # Initialisation: the Model returns the SDK's bool results as int.
    # ------------------------------------------------------------------

    @pyqtSlot(int, result=int)
    def initialize(self, fileDes: int) -> int:
        self._fd = fileDes
        return 1 if self._cam.setHidFd(fileDes) else 0

    # initializeFromDevicePath / deinitExtensionUnit: identical to the base class.

    # ------------------------------------------------------------------
    def _get(self, getter, signal) -> int:
        """GB(...) macro: ``uint8_t v; if (!get(v)) return 0; emit S(v); return 1;``"""
        ok, value = self._unpack(getter())
        if not ok:
            return 0
        signal.emit(int(value))
        return 1

    @staticmethod
    def _ret(ok) -> int:
        return 1 if ok else 0

    # ---- Special mode / Denoise ----------------------------------------

    @pyqtSlot(result=int)
    def getSpecialMode(self) -> int:
        return self._get(self._cam.getSpecialMode, self.specialModeReceived)

    @pyqtSlot(int, result=int)
    def setSpecialMode(self, mode: int) -> int:
        return self._ret(self._cam.setSpecialMode(mode))

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, value: int) -> int:
        return self._ret(self._cam.setDenoiseValue(value & 0xFF))

    # ---- Auto exposure ROI ---------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROI(self) -> int:
        ok, v = self._unpack(self._cam.getAutoExpROI())
        if not ok:
            return 0
        self.roiAutoExpReceived.emit(int(v["mode"]), int(v["windowSize"]))
        return 1

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAutoExpROI(self, m: int, w: int, h: int, x: int, y: int, s: int) -> int:
        return self._ret(self._cam.setAutoExpROI(m, w & 0xFFFFFFFF, h & 0xFFFFFFFF,
                                                 x & 0xFFFFFFFF, y & 0xFFFFFFFF, s & 0xFF))

    # ---- Orientation ---------------------------------------------------

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, h: bool, v: bool) -> int:
        return self._ret(self._cam.setOrientation(h, v))

    # ---- Exposure compensation -----------------------------------------

    @pyqtSlot(result=int)
    def getExposureCompensation(self) -> int:
        return self._get(self._cam.getExposureCompensation, self.exposureCompensationReceived)

    @pyqtSlot("uint", result=int)
    def setExposureCompensation(self, v: int) -> int:
        return self._ret(self._cam.setExposureCompensation(v))

    # ---- Frame rate ----------------------------------------------------

    @pyqtSlot(result=int)
    def getFrameRateCtrlValue(self) -> int:
        ok, values = self._unpack(self._cam.getFrameRateCtrlValue())
        if not ok:
            return 0
        v, minimum, maximum = values
        self.frameRateReceived.emit(int(v), int(minimum), int(maximum))
        return 1

    @pyqtSlot(int, result=int)
    def setFrameRateCtrlValue(self, v: int) -> int:
        return self._ret(self._cam.setFrameRateCtrlValue(v & 0xFF))

    # ---- Burst length / Anti-flicker / Wake on motion -------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, v: int) -> int:
        return self._ret(self._cam.setBurstLength(v & 0xFF))

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get(self._cam.getAntiFlickerMode, self.antiFlickerReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, v: int) -> int:
        return self._ret(self._cam.setAntiFlickerMode(v))

    @pyqtSlot(result=int)
    def getWakeOnMotion(self) -> int:
        return self._get(self._cam.getWakeOnMotion, self.wakeOnMotionReceived)

    @pyqtSlot(int, result=int)
    def setWakeOnMotion(self, v: int) -> int:
        return self._ret(self._cam.setWakeOnMotion(v))

    # ---- Face detection ------------------------------------------------

    @pyqtSlot(result=int)
    def getFaceDetection(self) -> int:
        ok, v = self._unpack(self._cam.getFaceDetection())
        if not ok:
            return 0
        self.faceDetectionReceived.emit(int(v["enabled"]), int(v["overlay"]), int(v["embeddedData"]))
        return 1

    @pyqtSlot(bool, bool, bool, result=int)
    def setFaceDetection(self, e: bool, o: bool, d: bool) -> int:
        return self._ret(self._cam.setFaceDetection(e, o, d))

    # ---- Stream / Flash ------------------------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, v: int) -> int:
        return self._ret(self._cam.setStreamMode(v))

    @pyqtSlot(result=int)
    def getFlashMode(self) -> int:
        return self._get(self._cam.getFlashMode, self.flashModeReceived)

    @pyqtSlot(int, result=int)
    def setFlashMode(self, v: int) -> int:
        return self._ret(self._cam.setFlashMode(v))

    # ---- Defaults ------------------------------------------------------

    @pyqtSlot(result=int)
    def setToDefaultValues(self) -> int:
        return self._ret(self._cam.setToDefaultValues())
