"""Network (RTSP) camera model (port of CamVistra/Model/src/NetworkCameraModel.cpp).

Wraps one ``sdk.NetStreamingInfo`` (NetStreamSDK). Frame grabbing is done
by the native FramePump in PreviewController.
"""

from __future__ import annotations

import math

from PyQt5.QtCore import QObject, pyqtSignal

from camvistra import feature_flags, tslog
from camvistra.native import sdk


def _lround(value: float) -> int:
    """std::lround: round half away from zero."""
    return int(math.floor(value + 0.5)) if value >= 0 else -int(math.floor(-value + 0.5))


class NetworkCameraModel(QObject):
    cameraOpened = pyqtSignal(int)
    cameraClosed = pyqtSignal()
    deviceStateChanged = pyqtSignal(int)
    devicesUpdated = pyqtSignal(int, int)
    fpsChanged = pyqtSignal(int, str)
    formatChanged = pyqtSignal(int, str)
    resolutionChanged = pyqtSignal(int, str)
    recordingStateChanged = pyqtSignal(bool)

    def __init__(self, parent: QObject | None = None, stream=None) -> None:
        super().__init__(parent)
        self.stream = stream if stream is not None else sdk.NetStreamingInfoInstance()
        self.fps = 0.0
        self.is_recording_started = False
        self.diagnostics_session_key = ""
        self.diagnostics_camera_name = ""
        if self.stream is not None:
            self.stream.SetRecordingStartedCallback(self._on_recording_state_changed)

    def set_diagnostics_session_key(self, key: str) -> None:
        self.diagnostics_session_key = key

    def set_diagnostics_camera_name(self, name: str) -> None:
        self.diagnostics_camera_name = name

    @staticmethod
    def _diagnostics():
        from camvistra.diagnostics import DiagnosticsManager
        return DiagnosticsManager.instance()

    def _on_recording_state_changed(self, is_started: bool) -> int:
        self.is_recording_started = is_started
        if is_started:
            self.recordingStateChanged.emit(True)
        return 1

    def register_dev_callback(self, index: int) -> int:
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")

        def on_device_state(state: int) -> int:  # called from a NetStreamSDK thread
            if state >= 0:
                self.devicesUpdated.emit(index, state)
            return 1

        result = self.stream.registerStateCallback(on_device_state)
        return tslog.log_result(result, result == 1)

    def open_camera(self, source: str) -> int:
        if not source:
            return tslog.log_result(0, False, "Source is empty")
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")
        result = self.stream.OpenCamera(source)
        if result == 1 and feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
            diag = self._diagnostics()
            if diag.has_session(self.diagnostics_session_key):
                diag.end_session(self.diagnostics_session_key)
            name = self.diagnostics_camera_name or source
            diag.start_session(self.diagnostics_session_key, name, 0.0, None, None)
        return tslog.log_result(result, result == 1)

    def request_stop(self) -> None:
        if self.stream is not None:
            self.stream.requestStop()

    def get_current_stream_format(self, index: int) -> int:
        if self.stream is not None:
            res, meta = self.stream.getCurrentStreamFormat()
            if res == 1:
                self.formatChanged.emit(index, meta["Compression"])
                self.resolutionChanged.emit(index, f"{meta['width']}x{meta['height']}")
                return tslog.log_result(1, True)
        return tslog.log_result(0, False)

    def close_camera(self, index: int) -> int:
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")
        result = self.stream.close()
        if result == 1:
            self.fpsChanged.emit(index, "")
            if feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
                self._diagnostics().end_session(self.diagnostics_session_key)
        return tslog.log_result(result, result == 1)

    def get_current_framerate(self, index: int) -> int:
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")
        # As in C++, pass the stored value in so it is kept until the SDK
        # has a new measurement ("0fps" before the first one).
        res, fps = self.stream.getCurrentFramerate(self.fps)
        if res != 1:
            return 0
        self.fps = fps
        self.fpsChanged.emit(index, f"{_lround(fps)}fps")  # C++ rounds with std::lround
        if feature_flags.DIAGNOSTICS_ENABLED and self.diagnostics_session_key:
            self._diagnostics().report_fps_sample(self.diagnostics_session_key, fps)
        return 1

    def start_video_recording(self, filename: str) -> int:
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")
        result = self.stream.startVideoRecording(filename)
        return tslog.log_result(result, result == 1)

    def stop_recording(self) -> int:
        if self.stream is None:
            return tslog.log_result(0, False, "Stream is not initialized")
        result = self.stream.stopRecording()
        return tslog.log_result(result, result == 1)
