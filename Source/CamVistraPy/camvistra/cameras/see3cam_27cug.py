"""See3CAM_27CUG controller.

Port of CamVistra/Model/src/See3CAM_27CUG_Model.cpp and
CamVistra/Controller/src/See3CAM_27CUG_Controller.cpp.
QML: context property ``see3cam27cugController``, type ``See3CAM27CUG``.

The 27CUG Model emits no status messages (the C++ Controller does not even
declare ``statusChanged``; the inherited signal is simply never emitted):
setters return the SDK result (1/0) and getters emit only on success.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_27CUG_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_27CUG

    class Values(enum.IntEnum):
        MASTER = 1
        TRIGGER = 2
        STROBE_OFF = 1
        STROBE_ON = 2
        RGB_IR_ENABLE = 1
        RGB = 2
        IR = 3
    Q_ENUM(Values)

    streamModeReceived = pyqtSignal(int, arguments=['mode'])
    strobeModeReceived = pyqtSignal(int, arguments=['mode'])
    cameraModeReceived = pyqtSignal(int, arguments=['mode'])
    orientationReceived = pyqtSignal(int, arguments=['orientation'])
    brightnessReceived = pyqtSignal(int, arguments=['value'])
    contrastReceived = pyqtSignal(int, arguments=['value'])
    gainReceived = pyqtSignal(int, arguments=['value'])
    minimumExposureReceived = pyqtSignal("uint", arguments=['exposure'])
    maximumExposureReceived = pyqtSignal("uint", arguments=['exposure'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNumber'])
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
        """G(...) macro: ``if (!camera->getX(v)) return 0; emit S(v); return 1;``"""
        ok, value = self._unpack(getter())
        if not ok:
            return 0
        signal.emit(int(value))
        return 1

    @staticmethod
    def _ret(ok) -> int:
        return 1 if ok else 0

    # ---- Stream / Strobe / Camera mode ---------------------------------

    @pyqtSlot(result=int)
    def getStreamMode(self) -> int:
        return self._get(self._cam.getStreamMode, self.streamModeReceived)

    @pyqtSlot(int, result=int)
    def setStreamMode(self, v: int) -> int:
        return self._ret(self._cam.setStreamMode(v))

    @pyqtSlot(result=int)
    def getStrobeMode(self) -> int:
        return self._get(self._cam.getStrobeMode, self.strobeModeReceived)

    @pyqtSlot(int, result=int)
    def setStrobeMode(self, v: int) -> int:
        return self._ret(self._cam.setStrobeMode(v))

    @pyqtSlot(result=int)
    def getCameraMode(self) -> int:
        return self._get(self._cam.getCameraMode, self.cameraModeReceived)

    @pyqtSlot(int, result=int)
    def setCameraMode(self, v: int) -> int:
        return self._ret(self._cam.setCameraMode(v))

    # ---- IR brightness / contrast / gain -------------------------------

    @pyqtSlot(result=int)
    def getBrightnessForIR(self) -> int:
        return self._get(self._cam.getBrightnessForIR, self.brightnessReceived)

    @pyqtSlot(int, result=int)
    def setBrightnessForIR(self, v: int) -> int:
        return self._ret(self._cam.setBrightnessForIR(v & 0xFF))

    @pyqtSlot(result=int)
    def getContrastForIR(self) -> int:
        return self._get(self._cam.getContrastForIR, self.contrastReceived)

    @pyqtSlot(int, result=int)
    def setContrastForIR(self, v: int) -> int:
        return self._ret(self._cam.setContrastForIR(v & 0xFF))

    @pyqtSlot(result=int)
    def getGainForIR(self) -> int:
        return self._get(self._cam.getGainForIR, self.gainReceived)

    @pyqtSlot(int, result=int)
    def setGainForIR(self, v: int) -> int:
        return self._ret(self._cam.setGainForIR(v & 0xFF))

    # ---- Orientation ---------------------------------------------------

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, h: bool, v: bool) -> int:
        return self._ret(self._cam.setOrientation(h, v))

    # ---- Exposure compensation limits ----------------------------------

    @pyqtSlot(result=int)
    def getMinimumExposureCompensation(self) -> int:
        return self._get(self._cam.getMinimumExposureCompensation, self.minimumExposureReceived)

    @pyqtSlot("uint", result=int)
    def setMinimumExposureCompensation(self, v: int) -> int:
        return self._ret(self._cam.setMinimumExposureCompensation(v))

    @pyqtSlot(result=int)
    def getMaximumExposureCompensation(self) -> int:
        return self._get(self._cam.getMaximumExposureCompensation, self.maximumExposureReceived)

    @pyqtSlot("uint", result=int)
    def setMaximumExposureCompensation(self, v: int) -> int:
        return self._ret(self._cam.setMaximumExposureCompensation(v))

    # ---- Serial / Defaults ---------------------------------------------

    @pyqtSlot(result=int)
    def getSerialNumber(self) -> int:
        ok, serial = self._unpack(self._cam.getSerialNumber())
        if not ok:
            return 0
        self.serialNumberReceived.emit(serial)
        return 1

    @pyqtSlot(result=int)
    def setToDefaultValues(self) -> int:
        return self._ret(self._cam.setToDefaultValues())
