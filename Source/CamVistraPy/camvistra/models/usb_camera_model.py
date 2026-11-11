"""USB (UVC) camera model (port of CamVistra/Model/src/UsbCameraModel.cpp).

Wraps one ``sdk.Camera`` (CAMSDK). Frame grabbing itself is done by the
native FramePump in PreviewController; this model covers open/close, formats,
UVC controls, recording and audio, and feeds the diagnostics session.
"""

from __future__ import annotations

from PyQt5.QtCore import QObject, pyqtSignal

from camvistra import feature_flags, tslog
from camvistra.cameras.base import IS_WINDOWS
from camvistra.native import sdk

UI_ID_TO_PROPERTY = {
    "brightness_s": 0, "contrast_s": 1, "hue_s": 2, "saturation": 3, "sharpness_s": 4,
    "gamma_s": 5, "wbMode": 6, "wbValue": 7, "backlightCompensation_d": 8, "gain_s": 9,
    "powerLineFreq_d": 10, "pan_s": 11, "tilt_s": 12, "roll_s": 13, "zoom_s": 14,
    "exposureMode": 15, "exposureTime": 16, "focusMode": 17, "focusValue": 18,
}
PROPERTY_TO_UI_ID = {v: k for k, v in UI_ID_TO_PROPERTY.items()}
UI_ID_TO_READABLE = {
    "brightness_s": "Brightness", "contrast_s": "Contrast", "hue_s": "Hue",
    "saturation": "Saturation", "sharpness_s": "Sharpness", "gamma_s": "Gamma",
    "wbMode": "White Balance Mode", "wbValue": "White Balance",
    "backlightCompensation_d": "Backlight Compensation", "gain_s": "Gain",
    "powerLineFreq_d": "Power Line Frequency", "pan_s": "Pan", "tilt_s": "Tilt",
    "roll_s": "Roll", "zoom_s": "Zoom", "exposureMode": "Exposure Mode",
    "exposureTime": "Exposure Time", "focusMode": "Focus Mode", "focusValue": "Focus",
}
# UsbCameraProperty values (CamSDK_enums.h)
UVC_WB_AUTO, UVC_BACKLIGHT, UVC_EXPOSURE_AUTO, UVC_FOCUS_AUTO = 6, 8, 15, 17


def _fps_key(text: str) -> int:
    try:
        return int(text[:-3]) if text.endswith("fps") else int(text)
    except ValueError:
        return 0  # QString::toInt() on non-numeric text


def fmt_number(value) -> str:
    """QString::number(double) formatting (%g with 6 significant digits)."""
    return f"{value:g}" if isinstance(value, float) else str(value)


class UsbCameraModel(QObject):
    cameraOpened = pyqtSignal(int)
    cameraClosed = pyqtSignal()
    deviceStateChanged = pyqtSignal(int)
    devicesUpdated = pyqtSignal(int, int)
    fpsChanged = pyqtSignal(int, str)
    formatChanged = pyqtSignal(int, str)
    resolutionChanged = pyqtSignal(int, str)
    fileDescriptor = pyqtSignal(int)
    cameraControlProperty = pyqtSignal("QVariantList")
    imagePropertiesMapChanged = pyqtSignal("QVariantMap")
    currentImagePropertyChanged = pyqtSignal(str, str, str)
    defaultUiValues = pyqtSignal("QVariantMap")
    statusChanged = pyqtSignal(str)
    recordingStateChanged = pyqtSignal(bool)
    audioVolumeChanged = pyqtSignal(int)
    muteChanged = pyqtSignal(bool)

    def __init__(self, parent: QObject | None = None, camera=None) -> None:
        super().__init__(parent)
        self.camera = camera if camera is not None else sdk.Camera()
        self.fps = 0
        self.is_recording_started = False
        self.default_values: dict[int, int] = {}
        self.image_properties: list[dict] = []
        self.image_properties_map: dict = {}
        self.diagnostics_session_key = ""
        self.diagnostics_camera_name = ""
        self._diag_adapter = None
        self.camera.SetRecordingStartedCallback(self._on_recording_state_changed)

    # ---- diagnostics wiring (set by PreviewController before open) -------
    def set_diagnostics_session_key(self, key: str) -> None:
        self.diagnostics_session_key = key

    def set_diagnostics_camera_name(self, name: str) -> None:
        self.diagnostics_camera_name = name

    def _diagnostics(self):
        from camvistra.diagnostics import DiagnosticsManager
        return DiagnosticsManager.instance()

    def _control_adapter(self):
        if self._diag_adapter is None:
            from camvistra.diagnostics import CamsdkUvcControlAdapter
            self._diag_adapter = CamsdkUvcControlAdapter()
        return self._diag_adapter

    # ---- callbacks -----------------------------------------------------
    def _on_recording_state_changed(self, is_started: bool) -> int:
        # Invoked from a CAMSDK thread; the signal is queued to receivers.
        self.is_recording_started = is_started
        if is_started:
            self.recordingStateChanged.emit(True)
        return 1

    # ---- open/close/frames ---------------------------------------------
    def open_camera(self, source: str) -> int:
        if not source:
            return tslog.log_result(0, False, "Source is empty")
        result = self.camera.OpenCamera(source)
        if result == 1 and feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
            diag = self._diagnostics()
            if diag.has_session(self.diagnostics_session_key):
                diag.end_session(self.diagnostics_session_key)
            name = self.diagnostics_camera_name or source
            diag.start_session(self.diagnostics_session_key, name, 0.0, None, self._control_adapter())
        return result

    def supports_audio(self) -> bool:
        """C++ returns false only for a Jetson Argus/Bayer sensor capture,
        which the Python port does not include."""
        return True

    def close_camera(self, index: int) -> int:
        result = self.camera.CloseCamera()
        if result == 1:
            self.fpsChanged.emit(index, "")
            if feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
                self._diagnostics().end_session(self.diagnostics_session_key)
        return result

    def get_current_stream_format(self, index: int) -> int:
        res, prop = self.camera.GetCurrentImageProperty()
        if res == 1:
            self.formatChanged.emit(index, prop["Compression"])
            self.resolutionChanged.emit(index, f"{prop['width']}x{prop['height']}")
            return 1
        return 0

    def get_current_framerate(self, index: int) -> int:
        # As in C++, pass the stored value in: the SDK only writes a new
        # reading once a second and otherwise leaves it unchanged, so the
        # label keeps its last value and reads "0fps" until the first
        # reading (the shared QML shows "-- | -- | 0fps" for such a camera).
        res, fps = self.camera.GetFramesPerSecond(self.fps)
        if res != 1:
            return 0
        self.fps = fps
        self.fpsChanged.emit(index, f"{fps}fps")
        if feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
            self._diagnostics().report_fps_sample(self.diagnostics_session_key, float(fps))
        return 1

    # ---- controls / properties -----------------------------------------
    def get_camera_control_property(self, control_id: int) -> int:
        ret, prop = self.camera.GetCameraControlProperty(control_id)
        if ret == 1:
            self.default_values[control_id] = prop["defaultVal"]
            self.cameraControlProperty.emit([prop["id"], prop["min"], prop["max"], prop["cur"],
                                             prop["step"], prop["automan"]])
        return ret

    def get_image_property(self) -> int:
        res, props = self.camera.GetImageProperty()
        if res != 1:
            return 0
        self.image_properties = list(props)
        properties_map: dict = {}
        for prop in props:
            fmt = prop["Compression"]
            resolution = f"{prop['width']}x{prop['height']}"
            fps = f"{fmt_number(prop['fps'])}fps"
            format_map = properties_map.setdefault(fmt, {})
            resolution_map = format_map.setdefault(resolution, {})
            fps_list = resolution_map.get("fps", [])
            if fps not in fps_list:
                fps_list.append(fps)
            fps_list.sort(key=_fps_key, reverse=True)  # descending
            resolution_map["fps"] = fps_list
        self.image_properties_map = properties_map
        self.imagePropertiesMapChanged.emit(properties_map)
        return 1

    def get_current_image_property(self) -> int:
        res, prop = self.camera.GetCurrentImageProperty()
        if res == 1:
            self.currentImagePropertyChanged.emit(
                prop["Compression"], f"{prop['width']}x{prop['height']}", f"{fmt_number(prop['fps'])}fps")
            return 1
        return 0

    def get_current_still_image_property(self) -> tuple[int, dict]:
        return self.camera.GetCurrentImageProperty()

    def get_file_descriptor(self) -> int:
        fd = self.get_file_descriptor_value()
        if fd >= 0:
            self.fileDescriptor.emit(fd)
            return tslog.log_result(1, True)
        return tslog.log_result(-1, False)

    def get_file_descriptor_value(self) -> int:
        """Open camera descriptor, or -1; emits nothing."""
        res, fd = self.camera.GetFileDescriptor()
        return fd if res == 1 else -1

    def set_camera_control_property(self, control_id: str, value: int) -> int:
        prop = UI_ID_TO_PROPERTY.get(control_id)
        if prop is None:
            return tslog.log_result(0, False, "Unknown camera control")
        ret = self.camera.SetCameraControlProperty(prop, value)
        if IS_WINDOWS and prop in (UVC_FOCUS_AUTO, UVC_EXPOSURE_AUTO, UVC_WB_AUTO):
            self.default_values[prop] = value
        readable = UI_ID_TO_READABLE.get(control_id, control_id)
        self.statusChanged.emit(f"{readable} set successfully" if ret == 1 else f"Failed to set {readable}")
        if ret == 1 and feature_flags.DIAGNOSTICS_ENABLED:
            self._control_adapter().report_control_change(readable, value)
        return ret

    def set_current_image_property(self, image_property: dict) -> int:
        res, _ = self.camera.SetImageProperty(image_property)
        return res

    def set_default_values(self) -> int:
        res, _ = self.camera.setDefaultConfiguration({"defaultCameraPropertyValues": self.default_values})
        if res != 1:
            self.statusChanged.emit("Failed to apply default camera configuration")
            return tslog.log_result(0, False)
        ui_values = {}
        for prop, value in sorted(self.default_values.items()):  # std::map order
            ui_id = PROPERTY_TO_UI_ID.get(prop)
            if ui_id is None:
                continue
            if prop in (UVC_EXPOSURE_AUTO, UVC_FOCUS_AUTO, UVC_WB_AUTO):
                ui_values[ui_id] = "AUTO" if value == 1 else "MANUAL"
            elif prop == UVC_BACKLIGHT:
                ui_values[ui_id] = "ON" if value == 1 else "OFF"
            else:
                ui_values[ui_id] = value
        self.defaultUiValues.emit(ui_values)
        self.statusChanged.emit("Default camera settings applied successfully")
        return tslog.log_result(1, True)

    # ---- recording -------------------------------------------------------
    def start_video_recording(self, filename: str) -> int:
        return self.camera.StartRecording(filename)

    def stop_recording(self) -> int:
        return self.camera.StopRecording()

    # ---- audio ----------------------------------------------------------
    def open_audio_device(self, device_path: str, audio_device_index: int) -> int:
        if not IS_WINDOWS and device_path:
            return self.camera.OpenAudioDevice(device_path)
        return self.camera.OpenAudioDevice(audio_device_index)

    def close_audio_device(self) -> int:
        return self.camera.CloseAudioDevice()

    def get_audio_range(self) -> tuple[int, float]:
        res, value = self.camera.GetAudioRange()
        if res == 1:
            self.audioVolumeChanged.emit(int(value * 100))
            return 1, value
        return 0, value

    def get_mute(self) -> tuple[int, bool]:
        res, flag = self.camera.GetMute()
        if res == 1:
            self.muteChanged.emit(bool(flag))
            return 1, bool(flag)
        return 0, bool(flag)

    def set_audio_range(self, value: float) -> int:
        return self.camera.SetAudioRange(value)

    def set_mute(self, flag: bool) -> int:
        return self.camera.SetMute(flag)

