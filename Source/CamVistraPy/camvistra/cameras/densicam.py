"""DensiCAM controller.

Port of CamVistra/Model/src/DensiCAM_Model.cpp and
CamVistra/Controller/src/DensiCAM_Controller.cpp.
QML: context property ``densicamController``, type ``DensiCAM``.

Unlike the See3CAM models, every DensiCAM getter ignores the SDK's return
value: it always emits the (possibly zero-initialised) values together with
the device status byte and returns 1. The HID button events reported by the
SDK (via ``setHidEventCallback``) are translated to ``actionPerformed``.
"""

from __future__ import annotations

import enum

from PyQt5.QtCore import Q_ENUM, pyqtSignal, pyqtSlot

from camvistra.cameras.base import IS_WINDOWS, CameraController
from camvistra.native import sdk

# HidEventType (CAMSDK/include/DensiCAM.h)
HID_EVENT_NONE = 0
HID_EVENT_VIDEO_RECORD_TOGGLE = 1
HID_EVENT_IMAGE_CAPTURE = 2
HID_EVENT_BUTTON_CAPTURE = 3

_HID_ACTIONS = {
    HID_EVENT_VIDEO_RECORD_TOGGLE: "VideoRecord",
    HID_EVENT_IMAGE_CAPTURE: "ImageCapture",
    HID_EVENT_BUTTON_CAPTURE: "ButtonSwImageCapture",
}

_RANGE = ("min", "max", "def", "cur", "res")


class DensiCAM_Controller(CameraController):
    SDK_CLASS = sdk.DensiCAM

    class SceneModeDensiCAM(enum.IntEnum):
        SCENE_INTRAORAL = 0x01
        SCENE_FACE = 0x02
    Q_ENUM(SceneModeDensiCAM)

    class ImageCaptureDensiCAM(enum.IntEnum):
        CAPTURE_BUTTON_SOFTWARE = 0x01
        CAPTURE_TWAIN_CAMVISTRA = 0x02
    Q_ENUM(ImageCaptureDensiCAM)

    class Status(enum.IntEnum):
        SUCCESS = 0x01
        FAILURE = 0x00
        DISABLE = 0xFF
    Q_ENUM(Status)

    # ---- Common ----
    firmwareVersionReceived = pyqtSignal(str, arguments=['firmwareVersion'])
    uniqueIDReceived = pyqtSignal(str, arguments=['uniqueID'])
    # ---- Extension Controls ----
    pixelTargetValueReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    denoiseValueReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    orientationReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    # ---- Command Controls: min, max, default, current, resolution, status ----
    brightnessReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    contrastReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    saturationReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    sharpnessReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    gainReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    gammaReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    manualWhiteBalanceReceived = pyqtSignal(int, int, int, int, int, int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    manualExposureReceived = pyqtSignal("uint", "uint", "uint", "uint", "uint", int, arguments=['minVal', 'maxVal', 'defVal', 'curVal', 'resVal', 'status'])
    # ---- Single-byte value controls: value, status ----
    autoWhiteBalanceReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    autoExposureReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    ledReceived = pyqtSignal(int, int, arguments=['value', 'status'])
    imageCaptureReceived = pyqtSignal(int, int, arguments=['mode', 'status'])
    sceneModeReceived = pyqtSignal(int, int, arguments=['mode', 'status'])
    actionPerformed = pyqtSignal(str, arguments=['action'])

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        # Invoked from the SDK's HID read thread; the emitted signal is
        # queued to the receivers' (GUI) thread by PyQt.
        self._cam.setHidEventCallback(self.onHidEvent)

    # ------------------------------------------------------------------
    # Initialization
    # ------------------------------------------------------------------

    @pyqtSlot(int, result=int)
    def initialize(self, fileDes: int) -> int:
        self._fd = fileDes
        if not IS_WINDOWS:
            self._cam.initialize(self._fd)
            # Bind the HID interface and start the button listener (actionPerformed).
            self._cam.setHidFd(self._fd)
        return 1

    @pyqtSlot(str, result=int)
    def initializeFromDevicePath(self, devicePath: str) -> int:
        if not IS_WINDOWS:
            return 0
        uvc_ok = self._cam.initUVCExtension(devicePath)
        # DensiCAM commands and the button listener use the camera's own HID
        # interface; initFromDevicePath opens it and starts the listener thread.
        hid_ok = self._cam.initFromDevicePath(devicePath)
        return 1 if (uvc_ok or hid_ok) else 0

    @pyqtSlot()
    def deinitExtensionUnit(self) -> None:
        if IS_WINDOWS:
            self._cam.deinitExtensionUnit()

    def onHidEvent(self, event: int) -> None:
        action = _HID_ACTIONS.get(int(event))
        if action is None:
            return
        self.actionPerformed.emit(action)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _get_value(self, getter, signal) -> int:
        _ok, value, status = getter()
        signal.emit(int(value), int(status))
        return 1

    def _get_range(self, getter, signal) -> int:
        _ok, rng, status = getter()
        signal.emit(*(rng[k] for k in _RANGE), int(status))
        return 1

    def _set_int(self, ok, success: str, failure: str) -> int:
        self.statusChanged.emit(success if ok else failure)
        return 1 if ok else 0

    # ------------------------------------------------------------------
    # Common Controls
    # ------------------------------------------------------------------

    @pyqtSlot(result=int)
    def getFirmwareVersion(self) -> int:
        ok, version = self._cam.readFirmwareVersion()
        if ok:
            self.firmwareVersionReceived.emit(version)
            return 1
        self.statusChanged.emit("Read firmware version failed")
        return 0

    @pyqtSlot(result=int)
    def getUniqueID(self) -> int:
        ok, uid = self._cam.getUniqueID()
        if ok:
            # snprintf("%08X%08X", part1, part2)
            self.uniqueIDReceived.emit(
                f"{int(uid['part1']) & 0xFFFFFFFF:08X}{int(uid['part2']) & 0xFFFFFFFF:08X}")
            return 1
        self.statusChanged.emit("Read unique ID failed")
        return 0

    @pyqtSlot(result=int)
    def deviceReset(self) -> int:
        return self._set_int(self._cam.deviceReset(),
                             "Device reset successfully", "Device reset failed")

    @pyqtSlot(result=int)
    def triggerFirmwareUpdate(self) -> int:
        return self._set_int(self._cam.triggerFirmwareUpdate(),
                             "Firmware update triggered successfully", "Trigger firmware update failed")

    @pyqtSlot(bool, result=int)
    def sendOSCode(self, isLinux: bool) -> int:
        ok, _status = self._cam.sendOSCode(bool(isLinux))
        if ok:
            self.statusChanged.emit("OS code (Linux) sent successfully" if isLinux
                                    else "OS code (Other) sent successfully")
            return 1
        self.statusChanged.emit("Send OS code failed")
        return 0

    # ------------------------------------------------------------------
    # Extension Controls (0x06)
    # ------------------------------------------------------------------

    @pyqtSlot(result=int)
    def getPixelTargetValue(self) -> int:
        return self._get_value(self._cam.getPixelTargetValue, self.pixelTargetValueReceived)

    @pyqtSlot(int, result=int)
    def setPixelTargetValue(self, value: int) -> int:
        return self._set_int(self._cam.setPixelTargetValue(value & 0xFFFF),
                             "Pixel target value set successfully", "Set pixel target value failed")

    @pyqtSlot(result=int)
    def getDenoiseValue(self) -> int:
        return self._get_value(self._cam.getDenoiseValue, self.denoiseValueReceived)

    @pyqtSlot(int, result=int)
    def setDenoiseValue(self, value: int) -> int:
        return self._set_int(self._cam.setDenoiseValue(value & 0xFF),
                             "Denoise value set successfully", "Set denoise value failed")

    @pyqtSlot(result=int)
    def getOrientation(self) -> int:
        return self._get_value(self._cam.getOrientation, self.orientationReceived)

    @pyqtSlot(int, result=int)
    def setOrientation(self, value: int) -> int:
        return self._set_int(self._cam.setOrientation(value & 0xFF),
                             "Orientation set successfully", "Set orientation failed")

    @pyqtSlot(result=int)
    def resetDevice(self) -> int:
        return self._set_int(self._cam.resetDevice(),
                             "Device reset successfully", "Device reset failed")

    @pyqtSlot(result=int)
    def restoreDefaults(self) -> int:
        return self._set_int(self._cam.restoreDefaults(),
                             "Defaults restored successfully", "Restore defaults failed")

    # ------------------------------------------------------------------
    # Command Controls (0x07)
    # ------------------------------------------------------------------

    @pyqtSlot(result=int)
    def getBrightness(self) -> int:
        return self._get_range(self._cam.getBrightness, self.brightnessReceived)

    @pyqtSlot(int, result=int)
    def setBrightness(self, value: int) -> int:
        return self._set_int(self._cam.setBrightness(value & 0xFF),
                             "Brightness set successfully", "Set brightness failed")

    @pyqtSlot(result=int)
    def getContrast(self) -> int:
        return self._get_range(self._cam.getContrast, self.contrastReceived)

    @pyqtSlot(int, result=int)
    def setContrast(self, value: int) -> int:
        return self._set_int(self._cam.setContrast(value & 0xFF),
                             "Contrast set successfully", "Set contrast failed")

    @pyqtSlot(result=int)
    def getSaturation(self) -> int:
        return self._get_range(self._cam.getSaturation, self.saturationReceived)

    @pyqtSlot(int, result=int)
    def setSaturation(self, value: int) -> int:
        return self._set_int(self._cam.setSaturation(value & 0xFF),
                             "Saturation set successfully", "Set saturation failed")

    @pyqtSlot(result=int)
    def getSharpness(self) -> int:
        return self._get_range(self._cam.getSharpness, self.sharpnessReceived)

    @pyqtSlot(int, result=int)
    def setSharpness(self, value: int) -> int:
        return self._set_int(self._cam.setSharpness(value & 0xFF),
                             "Sharpness set successfully", "Set sharpness failed")

    @pyqtSlot(result=int)
    def getGamma(self) -> int:
        return self._get_range(self._cam.getGamma, self.gammaReceived)

    @pyqtSlot(int, result=int)
    def setGamma(self, value: int) -> int:
        return self._set_int(self._cam.setGamma(value & 0xFFFF),
                             "Gamma set successfully", "Set gamma failed")

    @pyqtSlot(result=int)
    def getManualWhiteBalance(self) -> int:
        return self._get_range(self._cam.getManualWhiteBalance, self.manualWhiteBalanceReceived)

    @pyqtSlot(int, result=int)
    def setManualWhiteBalance(self, value: int) -> int:
        return self._set_int(self._cam.setManualWhiteBalance(value & 0xFFFF),
                             "Manual white balance set successfully", "Set manual white balance failed")

    @pyqtSlot(result=int)
    def getAutoWhiteBalance(self) -> int:
        return self._get_value(self._cam.getAutoWhiteBalance, self.autoWhiteBalanceReceived)

    @pyqtSlot(int, result=int)
    def setAutoWhiteBalance(self, value: int) -> int:
        return self._set_int(self._cam.setAutoWhiteBalance(value & 0xFF),
                             "Auto white balance set successfully", "Set auto white balance failed")

    @pyqtSlot(result=int)
    def getGain(self) -> int:
        return self._get_range(self._cam.getGain, self.gainReceived)

    @pyqtSlot(int, result=int)
    def setGain(self, value: int) -> int:
        return self._set_int(self._cam.setGain(value & 0xFF),
                             "Gain set successfully", "Set gain failed")

    @pyqtSlot(result=int)
    def getManualExposure(self) -> int:
        return self._get_range(self._cam.getManualExposure, self.manualExposureReceived)

    @pyqtSlot("uint", result=int)
    def setManualExposure(self, value: int) -> int:
        return self._set_int(self._cam.setManualExposure(value & 0xFFFFFFFF),
                             "Manual exposure set successfully", "Set manual exposure failed")

    @pyqtSlot(result=int)
    def getAutoExposure(self) -> int:
        return self._get_value(self._cam.getAutoExposure, self.autoExposureReceived)

    @pyqtSlot(int, result=int)
    def setAutoExposure(self, value: int) -> int:
        return self._set_int(self._cam.setAutoExposure(value & 0xFF),
                             "Auto exposure set successfully", "Set auto exposure failed")

    @pyqtSlot(result=int)
    def getLED(self) -> int:
        return self._get_value(self._cam.getLED, self.ledReceived)

    @pyqtSlot(int, result=int)
    def setLED(self, value: int) -> int:
        return self._set_int(self._cam.setLED(value & 0xFF),
                             "LED set successfully", "Set LED failed")

    @pyqtSlot(result=int)
    def saveConfiguration(self) -> int:
        return self._set_int(self._cam.saveConfiguration(),
                             "Configuration saved successfully", "Save configuration failed")

    @pyqtSlot(result=int)
    def getImageCaptureMode(self) -> int:
        return self._get_value(self._cam.getImageCaptureMode, self.imageCaptureReceived)

    @pyqtSlot(int, result=int)
    def setImageCaptureMode(self, mode: int) -> int:
        # static_cast<DensiCAMImageCapture>(mode): enum class with uint8_t underlying type
        return self._set_int(self._cam.setImageCaptureMode(mode & 0xFF),
                             "Image capture mode set successfully", "Set image capture mode failed")

    @pyqtSlot(result=int)
    def getSceneMode(self) -> int:
        return self._get_value(self._cam.getSceneMode, self.sceneModeReceived)

    @pyqtSlot(int, result=int)
    def setSceneMode(self, mode: int) -> int:
        return self._set_int(self._cam.setSceneMode(mode & 0xFF),
                             "Scene mode set successfully", "Set scene mode failed")
