"""See3CAM_CU22 controller.

Port of CamVistra/Model/src/See3CAM_CU22_Model.cpp and
CamVistra/Controller/src/See3CAM_CU22_Controller.cpp.
QML: context property ``see3camcu22Controller``, type ``See3CAMCU22``.
"""

from __future__ import annotations

from PyQt5.QtCore import pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU22_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU22

    sensorModeReceived = pyqtSignal(int, arguments=['sensorMode'])
    cameraModeReceived = pyqtSignal(int, arguments=['cameraMode'])
    specialEffectsReceived = pyqtSignal(int, arguments=['effectMode'])
    autoExpROIModeReceived = pyqtSignal(int, int, arguments=['roiMode', 'winSize'])
    flipModeReceived = pyqtSignal(int, arguments=['flipMode'])
    colorKillValueReceived = pyqtSignal(int, arguments=['value'])
    burstLengthReceived = pyqtSignal(int, arguments=['burstLength'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['flickerMode'])
    denoiseModeReceived = pyqtSignal(int, arguments=['mode'])
    lscModeReceived = pyqtSignal(int, arguments=['mode'])
    # Declared by the C++ Model/Controller but never emitted.
    serialNumberReceived = pyqtSignal(str, arguments=['serialNum'])
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
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

    # ---- Sensor / Camera mode -------------------------------------------

    @pyqtSlot(result=int)
    def getSensorMode(self) -> int:
        return self._get_value(self._cam.getSensorMode, self.sensorModeReceived)

    @pyqtSlot(int, result=int)
    def setSensorMode(self, sensorMode: int) -> int:
        return self._set_int(self._cam.setSensorMode(sensorMode & 0xFF),
                             "Sensor mode set successfully", "Set sensor mode failed")

    @pyqtSlot(result=int)
    def getCameraMode(self) -> int:
        return self._get_value(self._cam.getCameraMode, self.cameraModeReceived)

    @pyqtSlot(int, result=int)
    def setCameraMode(self, cameraMode: int) -> int:
        return self._set_int(self._cam.setCameraMode(cameraMode & 0xFF),
                             "Camera mode set successfully", "Set camera mode failed")

    # ---- Special effects ------------------------------------------------

    @pyqtSlot(result=int)
    def getSpecialEffects(self) -> int:
        return self._get_value(self._cam.getSpecialEffects, self.specialEffectsReceived)

    @pyqtSlot(int, result=int)
    def setSpecialEffects(self, effectMode: int) -> int:
        return self._set_int(self._cam.setSpecialEffects(effectMode & 0xFF),
                             "Special effects set successfully", "Set special effects failed")

    # ---- Auto-exposure ROI ---------------------------------------------

    @pyqtSlot(result=int)
    def getAutoExpROIMode(self) -> int:
        ok, v = self._cam.getAutoExpROIMode()
        if ok:
            self.autoExpROIModeReceived.emit(int(v["mode"]), int(v["wnsize"]))
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

    # ---- Flip -----------------------------------------------------------

    @pyqtSlot(result=int)
    def getFlipMode(self) -> int:
        return self._get_value(self._cam.getFlipMode, self.flipModeReceived)

    @pyqtSlot(bool, bool, result=int)
    def setFlipMode(self, horzFlip: bool, vertFlip: bool) -> int:
        return self._set_int(self._cam.setFlipMode(bool(horzFlip), bool(vertFlip)),
                             "Flip mode set successfully", "Set flip mode failed")

    # ---- Color kill -----------------------------------------------------

    @pyqtSlot(result=int)
    def getColorKillValue(self) -> int:
        return self._get_value(self._cam.getColorKillValue, self.colorKillValueReceived)

    @pyqtSlot(int, result=int)
    def setColorKillValue(self, colorKillValue: int) -> int:
        return self._set_int(self._cam.setColorKillValue(colorKillValue & 0xFF),
                             "Color kill value set successfully", "Set color kill value failed")

    # ---- Burst length ---------------------------------------------------

    @pyqtSlot(result=int)
    def getBurstLength(self) -> int:
        return self._get_value(self._cam.getBurstLength, self.burstLengthReceived)

    @pyqtSlot(int, result=int)
    def setBurstLength(self, burstLength: int) -> int:
        return self._set_int(self._cam.setBurstLength(burstLength & 0xFF),
                             "Burst length set successfully", "Set burst length failed")

    # ---- Anti-flicker ---------------------------------------------------

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get_value(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, flickerMode: int) -> int:
        return self._set_int(self._cam.setAntiFlickerMode(flickerMode & 0xFF),
                             "Anti-flicker mode set successfully", "Set anti-flicker mode failed")

    # ---- Denoise --------------------------------------------------------

    @pyqtSlot(result=int)
    def getDenoiseMode(self) -> int:
        return self._get_value(self._cam.getDenoiseMode, self.denoiseModeReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseMode(self, denoiseMode: int) -> int:
        return self._set_int(self._cam.setDenoiseMode(denoiseMode & 0xFF),
                             "Denoise mode set successfully", "Set denoise mode failed")

    # ---- Lens shading correction ----------------------------------------

    @pyqtSlot(result=int)
    def getLSCMode(self) -> int:
        return self._get_value(self._cam.getLSCMode, self.lscModeReceived)

    @pyqtSlot(int, result=int)
    def setLSCMode(self, lscMode: int) -> int:
        return self._set_int(self._cam.setLSCMode(lscMode & 0xFF),
                             "Lens correction mode set successfully", "Set lens correction mode failed")

    # ---- Restore defaults -----------------------------------------------

    @pyqtSlot(result=int)
    def restoreDefault(self) -> int:
        return self._set_int(self._cam.restoreDefault(),
                             "Default settings restored", "Restore default settings failed")
