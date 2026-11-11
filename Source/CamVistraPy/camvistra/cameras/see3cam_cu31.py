"""See3CAM_CU31 controller.

Port of CamVistra/Model/src/See3CAM_CU31_Model.cpp and
CamVistra/Controller/src/See3CAM_CU31_Controller.cpp.
QML: context property ``see3camcu31Controller``, type ``See3CAMCU31``.

The CU31 Model emits no status messages (``statusChanged`` is declared but
never emitted): setters return the SDK result (1/0) and getters emit only on
success.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import CameraController
from camvistra.native import sdk


class See3CAM_CU31_Controller(CameraController):
    SDK_CLASS = sdk.See3CAM_CU31

    class Values(enum.IntEnum):
        NORMAL = 0
        HORIZONTAL = 1
        VERTICAL = 2
        ROTATE_180 = 3
        RNR_DISABLE = 0
        RNR_ENABLE = 1
        DISABLE_TRIGGER = 0
        READOUT_TRIGGER = 1
        SHUTTER_TRIGGER = 2
        AE_RELEASE = 0
        AE_HOLD = 1
        AWB_RELEASE = 0
        AWB_HOLD = 1
        MODE_AUTO = 0
        MODE_50Hz = 1
        MODE_60Hz = 2
        MODE_DISABLE = 3
        AUTO = 0
        LOW_LIGHT = 1
        LED = 2
        MANUAL_PRESET = 0
        USER_PRESET_1 = 1
        USER_PRESET_2 = 2
        PRESET_SELECT = 0
        PRESET_SAVE = 1
        PRESET_DEFAULT = 2
    Q_ENUM(Values)

    orientationReceived = pyqtSignal(int, arguments=['orientation'])
    rawNoiseReductionReceived = pyqtSignal(int, arguments=['status'])
    triggerModeReceived = pyqtSignal(int, arguments=['mode'])
    aeConvergenceSpeedReceived = pyqtSignal(int, arguments=['speed'])
    autoExposureStatusReceived = pyqtSignal(int, arguments=['status'])
    awbStatusReceived = pyqtSignal(int, arguments=['status'])
    temperatureReceived = pyqtSignal(float, arguments=['temperature'])
    antiFlickerModeReceived = pyqtSignal(int, arguments=['mode'])
    cameraModeReceived = pyqtSignal(int, arguments=['mode'])
    aeWindowOverlayReceived = pyqtSignal(int, arguments=['status'])
    aeWindowDimensionsReceived = pyqtSignal(int, int, int, int, arguments=['width', 'height', 'xStart', 'yStart'])
    aeMaskOverlayReceived = pyqtSignal(int, arguments=['status'])
    aeMaskDimensionsReceived = pyqtSignal(bool, int, int, int, int, int, int, arguments=['includeId', 'id', 'state', 'width', 'height', 'xStart', 'yStart'])
    awbWindowOverlayReceived = pyqtSignal(int, arguments=['status'])
    awbWindowDimensionsReceived = pyqtSignal(int, int, int, int, arguments=['width', 'height', 'xStart', 'yStart'])
    awbMaskOverlayReceived = pyqtSignal(int, arguments=['status'])
    awbMaskDimensionsReceived = pyqtSignal(bool, int, int, int, int, int, int, arguments=['includeId', 'id', 'state', 'width', 'height', 'xStart', 'yStart'])
    embeddedDataReceived = pyqtSignal(int, arguments=['status'])
    presetPropertiesReceived = pyqtSignal(int, int, arguments=['mode', 'action'])
    uvcControlValuesReceived = pyqtSignal(int, int, int, int, int, int, "uint", arguments=['brightness', 'contrast', 'saturation', 'sharpness', 'gain', 'exposureMode', 'exposureTime'])
    serialNumberReceived = pyqtSignal(str, arguments=['serialNumber'])
    ispFirmwareVersionReceived = pyqtSignal(str, arguments=['version'])
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
        """GET_BYTE macro: ``uint8_t v = 0; if (!get(v)) return 0; emit S(v); return 1;``"""
        ok, value = self._unpack(getter())
        if not ok:
            return 0
        signal.emit(int(value))
        return 1

    @staticmethod
    def _ret(ok) -> int:
        return 1 if ok else 0

    def _get_window(self, getter, signal) -> int:
        ok, v = self._unpack(getter())
        if not ok:
            return 0
        signal.emit(int(v["width"]), int(v["height"]), int(v["xStart"]), int(v["yStart"]))
        return 1

    def _get_mask(self, getter, signal, includeId: bool, maskId: int) -> int:
        ok, v = self._unpack(getter(maskId & 0xFF))
        if not ok:
            return 0
        signal.emit(bool(includeId), int(v["id"]), int(v["state"]),
                    int(v["width"]), int(v["height"]), int(v["xStart"]), int(v["yStart"]))
        return 1

    # ---- Orientation / RNR / Trigger ------------------------------------

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(bool, bool, result=int)
    def setOrientation(self, h: bool, v: bool) -> int:
        return self._ret(self._cam.setOrientation(h, v))

    @pyqtSlot(result=int)
    def getRawNoiseReductionStatus(self) -> int:
        return self._get(self._cam.getRawNoiseReductionStatus, self.rawNoiseReductionReceived)

    @pyqtSlot(int, result=int)
    def setRawNoiseReductionStatus(self, v: int) -> int:
        return self._ret(self._cam.setRawNoiseReductionStatus(v))

    @pyqtSlot(result=int)
    def getTriggerMode(self) -> int:
        return self._get(self._cam.getTriggerMode, self.triggerModeReceived)

    @pyqtSlot(int, result=int)
    def setTriggerMode(self, v: int) -> int:
        return self._ret(self._cam.setTriggerMode(v))

    # ---- AE / AWB -------------------------------------------------------

    @pyqtSlot(result=int)
    def getAEConvergenceSpeed(self) -> int:
        return self._get(self._cam.getAEConvergenceSpeed, self.aeConvergenceSpeedReceived)

    @pyqtSlot(int, result=int)
    def setAEConvergenceSpeed(self, v: int) -> int:
        return self._ret(self._cam.setAEConvergenceSpeed(v & 0xFF))

    @pyqtSlot(result=int)
    def getAutoExposureStatus(self) -> int:
        return self._get(self._cam.getAutoExposureStatus, self.autoExposureStatusReceived)

    @pyqtSlot(int, result=int)
    def setAutoExposureStatus(self, v: int) -> int:
        return self._ret(self._cam.setAutoExposureStatus(v))

    @pyqtSlot(result=int)
    def getAWBStatus(self) -> int:
        return self._get(self._cam.getAWBStatus, self.awbStatusReceived)

    @pyqtSlot(int, result=int)
    def setAWBStatus(self, v: int) -> int:
        return self._ret(self._cam.setAWBStatus(v))

    # ---- Temperature / Anti-flicker / Camera mode -----------------------

    @pyqtSlot(result=int)
    def readTemperature(self) -> int:
        ok, v = self._unpack(self._cam.readTemperature())
        if not ok:
            return 0
        self.temperatureReceived.emit(float(v))
        return 1

    @pyqtSlot(result=int)
    def getAntiFlickerMode(self) -> int:
        return self._get(self._cam.getAntiFlickerMode, self.antiFlickerModeReceived)

    @pyqtSlot(int, result=int)
    def setAntiFlickerMode(self, v: int) -> int:
        return self._ret(self._cam.setAntiFlickerMode(v))

    @pyqtSlot(result=int)
    def getCameraMode(self) -> int:
        return self._get(self._cam.getCameraMode, self.cameraModeReceived)

    @pyqtSlot(int, result=int)
    def setCameraMode(self, v: int) -> int:
        return self._ret(self._cam.setCameraMode(v))

    # ---- AE window / mask ----------------------------------------------

    @pyqtSlot(result=int)
    def getAEWindowOverlay(self) -> int:
        return self._get(self._cam.getAEWindowOverlay, self.aeWindowOverlayReceived)

    @pyqtSlot(int, result=int)
    def setAEWindowOverlay(self, v: int) -> int:
        return self._ret(self._cam.setAEWindowOverlay(v & 0xFF))

    @pyqtSlot(result=int)
    def getAEWindowDimensions(self) -> int:
        return self._get_window(self._cam.getAEWindowDimensions, self.aeWindowDimensionsReceived)

    @pyqtSlot(int, int, int, int, result=int)
    def setAEWindowDimensions(self, w: int, h: int, x: int, y: int) -> int:
        return self._ret(self._cam.setAEWindowDimensions(w & 0xFFFF, h & 0xFFFF, x & 0xFFFF, y & 0xFFFF))

    @pyqtSlot(result=int)
    def getAEMaskOverlay(self) -> int:
        return self._get(self._cam.getAEMaskOverlay, self.aeMaskOverlayReceived)

    @pyqtSlot(int, result=int)
    def setAEMaskOverlay(self, v: int) -> int:
        return self._ret(self._cam.setAEMaskOverlay(v & 0xFF))

    @pyqtSlot(bool, int, result=int)
    def getAEMaskDimensions(self, includeId: bool, maskId: int) -> int:
        return self._get_mask(self._cam.getAEMaskDimensions, self.aeMaskDimensionsReceived, includeId, maskId)

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAEMaskDimensions(self, maskId: int, s: int, w: int, h: int, x: int, y: int) -> int:
        return self._ret(self._cam.setAEMaskDimensions(maskId & 0xFF, s & 0xFF, w & 0xFFFF, h & 0xFFFF,
                                                       x & 0xFFFF, y & 0xFFFF))

    # ---- AWB window / mask ---------------------------------------------

    @pyqtSlot(result=int)
    def getAWBWindowOverlay(self) -> int:
        return self._get(self._cam.getAWBWindowOverlay, self.awbWindowOverlayReceived)

    @pyqtSlot(int, result=int)
    def setAWBWindowOverlay(self, v: int) -> int:
        return self._ret(self._cam.setAWBWindowOverlay(v & 0xFF))

    @pyqtSlot(result=int)
    def getAWBWindowDimensions(self) -> int:
        return self._get_window(self._cam.getAWBWindowDimensions, self.awbWindowDimensionsReceived)

    @pyqtSlot(int, int, int, int, result=int)
    def setAWBWindowDimensions(self, w: int, h: int, x: int, y: int) -> int:
        return self._ret(self._cam.setAWBWindowDimensions(w & 0xFFFF, h & 0xFFFF, x & 0xFFFF, y & 0xFFFF))

    @pyqtSlot(result=int)
    def getAWBMaskOverlay(self) -> int:
        return self._get(self._cam.getAWBMaskOverlay, self.awbMaskOverlayReceived)

    @pyqtSlot(int, result=int)
    def setAWBMaskOverlay(self, v: int) -> int:
        return self._ret(self._cam.setAWBMaskOverlay(v & 0xFF))

    @pyqtSlot(bool, int, result=int)
    def getAWBMaskDimensions(self, includeId: bool, maskId: int) -> int:
        return self._get_mask(self._cam.getAWBMaskDimensions, self.awbMaskDimensionsReceived, includeId, maskId)

    @pyqtSlot(int, int, int, int, int, int, result=int)
    def setAWBMaskDimensions(self, maskId: int, s: int, w: int, h: int, x: int, y: int) -> int:
        return self._ret(self._cam.setAWBMaskDimensions(maskId & 0xFF, s & 0xFF, w & 0xFFFF, h & 0xFFFF,
                                                        x & 0xFFFF, y & 0xFFFF))

    # ---- Embedded data / Preset ----------------------------------------

    @pyqtSlot(result=int)
    def getEmbeddedData(self) -> int:
        return self._get(self._cam.getEmbeddedData, self.embeddedDataReceived)

    @pyqtSlot(int, result=int)
    def setEmbeddedData(self, v: int) -> int:
        return self._ret(self._cam.setEmbeddedData(v & 0xFF))

    @pyqtSlot(result=int)
    def getPresetMode(self) -> int:
        ok, v = self._unpack(self._cam.getPresetMode())
        if not ok:
            return 0
        self.presetPropertiesReceived.emit(int(v["mode"]), int(v["operation"]))
        return 1

    @pyqtSlot(int, int, result=int)
    def setPresetMode(self, mode: int, operation: int) -> int:
        return self._ret(self._cam.setPresetMode(mode, operation))

    # ---- UVC controls / Cross-still / Defaults --------------------------

    @pyqtSlot(result=int)
    def getUVCControls(self) -> int:
        ok, v = self._unpack(self._cam.getUVCControls())
        if not ok:
            return 0
        self.uvcControlValuesReceived.emit(int(v["brightness"]), int(v["contrast"]), int(v["saturation"]),
                                           int(v["sharpness"]), int(v["gain"]), int(v["exposureMode"]),
                                           int(v["exposureTime"]))
        return 1

    @pyqtSlot(result=int)
    def setPropertiesForCrossStill(self) -> int:
        return self._ret(self._cam.setPropertiesForCrossStill())

    @pyqtSlot(result=int)
    def setToDefaultValues(self) -> int:
        return self._ret(self._cam.setToDefaultValues())

    # ---- Serial number / ISP firmware ------------------------------------

    @pyqtSlot(result=int)
    def get64BitSerialNumber(self) -> int:
        ok, v = self._unpack(self._cam.get64BitSerialNumber())
        if not ok:
            return 0
        self.serialNumberReceived.emit(str(int(v)))  # QString::number(uint64_t): decimal
        return 1

    @pyqtSlot(result=int)
    def readISPFirmwareVersion(self) -> int:
        ok, v = self._unpack(self._cam.readISPFirmwareVersion())
        if not ok:
            return 0
        self.ispFirmwareVersionReceived.emit(
            f'{int(v["major"])}.{int(v["minor1"])}.{int(v["minor2"])}.{int(v["minor3"])}')
        return 1
