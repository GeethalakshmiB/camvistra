"""Preview, still capture and recording (port of CamVistra/Controller/src/PreviewController.cpp).

QML context property: ``prevController``.

Per open camera the C++ controller ran three std::threads (grab, process,
still). Here grab + process are the native ``sdk.FramePump`` (no pixel data
crosses into Python) and the still-capture loop is a Python thread that
blocks in native code until a capture frame is ready; image conversion and
encoding are native (``sdk.imaging``, byte-identical to the C++ output).
"""

from __future__ import annotations

import math
import os
import re
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime

from PyQt5.QtCore import (Q_ARG, Q_RETURN_ARG, QFile, QMetaObject, QObject, Qt, QTimer, pyqtProperty,
                          pyqtSignal, pyqtSlot)
from PyQt5.QtQuick import QQuickItem

from camvistra import feature_flags, tslog
from camvistra.branding import CAPTURE_FILE_PREFIX
from camvistra.controllers.device_controller import read_qrc_json
from camvistra.controllers.recording_worker import RecordingThread
from camvistra.controls.opengl_display import FramebufferObject
from camvistra.device_enums import DeviceEnums
from camvistra.models.network_camera_model import NetworkCameraModel
from camvistra.models.usb_camera_model import UsbCameraModel
from camvistra.native import sdk

PF = sdk.Pixelformat
MAX_CAMERAS = 8
STILL_WAIT_S = 0.25  # poll interval of the still thread's native wait


def _clamp(value: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, value))


def _qstring_to_int(text: str) -> int:
    try:
        return int(text.strip())
    except ValueError:
        return 0


def _parse_resolution(resolution: str) -> list[int] | None:
    parts = [p for p in resolution.split("x") if p]  # Qt::SkipEmptyParts
    if len(parts) == 2:
        return [_qstring_to_int(parts[0]), _qstring_to_int(parts[1])]
    return None


def _strip_fps(fps: str) -> int:
    lower = fps.lower()
    while "fps" in lower:  # QString::replace("fps", "", Qt::CaseInsensitive)
        i = lower.index("fps")
        fps, lower = fps[:i] + fps[i + 3:], lower[:i] + lower[i + 3:]
    return _qstring_to_int(fps)


@dataclass
class CameraContext:
    """Per-camera state (C++ CameraContext). Fields read by the grab/process
    threads (width, height, pixel format, still* and the *Capture flags)
    live in the native pump; the rest are plain Python attributes."""

    capture: object                  # this camera's sdk.CaptureFlag
    name: str = ""                   # friendly device name, used in file names
    usb_model: UsbCameraModel | None = None
    net_model: NetworkCameraModel | None = None
    pump: object | None = None
    still_thread: threading.Thread | None = None
    viewport_width: int = 0
    viewport_height: int = 0
    fps: int = 0
    x: int = 0
    y: int = 0
    view_port_w: int = 0
    view_port_h: int = 0
    still_fps: int = 0
    still_file_fmt: str = ""
    device_path: str = ""
    # Values mirrored into the pump once it exists.
    _pending: dict = field(default_factory=dict)

    # ---- pump-backed fields -------------------------------------------
    def _get(self, name, default):
        return getattr(self.pump, name) if self.pump is not None else self._pending.get(name, default)

    def _setp(self, name, value):
        if self.pump is not None:
            setattr(self.pump, name, value)
        else:
            self._pending[name] = value

    width = property(lambda s: s._get("width", 0), lambda s, v: s._setp("width", v))
    height = property(lambda s: s._get("height", 0), lambda s, v: s._setp("height", v))
    pixel_value = property(lambda s: s._get("pixelValue", ""), lambda s, v: s._setp("pixelValue", v))
    still_width = property(lambda s: s._get("stillWidth", 0), lambda s, v: s._setp("stillWidth", v))
    still_height = property(lambda s: s._get("stillHeight", 0), lambda s, v: s._setp("stillHeight", v))
    still_pixel_value = property(lambda s: s._get("stillPixelValue", ""),
                                 lambda s, v: s._setp("stillPixelValue", v))
    pix_value = property(lambda s: s._get("pixValue", 0), lambda s, v: s._setp("pixValue", v))
    is_cross_still_capture = property(lambda s: s._get("isCrossStillCapture", False),
                                      lambda s, v: s._setp("isCrossStillCapture", v))
    is_set_image_property = property(lambda s: s._get("isSetImageProperty", False),
                                     lambda s, v: s._setp("isSetImageProperty", v))
    is_buffer_initialized = property(lambda s: s._get("isBufferInitialized", False),
                                     lambda s, v: s._setp("isBufferInitialized", v))

    @property
    def streaming(self) -> bool:
        return self.pump is not None and self.pump.streaming

    def attach_pump(self, pump) -> None:
        self.pump = pump
        for name, value in self._pending.items():
            setattr(pump, name, value)
        self._pending.clear()


class PreviewController(QObject):
    fboCreated = pyqtSignal()
    cameraOpened = pyqtSignal(int, arguments=['index'])
    cameraClosed = pyqtSignal()
    usbDeviceAdded = pyqtSignal(int, arguments=['index'])
    usbDeviceRemoved = pyqtSignal(int, int, arguments=['removedIndex', 'newCount'])
    devicesUpdated = pyqtSignal(int, int, arguments=['index', 'devStat'])
    formatChanged = pyqtSignal(int, str, arguments=['index', 'format'])
    resolutionChanged = pyqtSignal(int, str, arguments=['index', 'resolution'])
    fpsChanged = pyqtSignal(int, str, arguments=['index', 'fpsVal'])
    statusChanged = pyqtSignal(str, arguments=['status'])
    centerStatusChanged = pyqtSignal(str, arguments=['status'])
    viewPortChanged = pyqtSignal(int, int, int, int, int, arguments=['index', 'x', 'y', 'viewW', 'viewH'])
    jsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    extensionJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    cameraControlProperty = pyqtSignal("QVariantList", arguments=['propList'])
    imagePropertiesMapChanged = pyqtSignal("QVariantMap", arguments=['propertiesMap'])
    currentImagePropertyChanged = pyqtSignal(str, str, str, arguments=['format', 'resolution', 'fps'])
    fileDescriptor = pyqtSignal(int, arguments=['fd'])
    setImagePropertySuccess = pyqtSignal(int, arguments=['index'])
    defaultUiValues = pyqtSignal("QVariantMap", arguments=['values'])
    setImagePropertyFailed = pyqtSignal(int, arguments=['index'])
    recordingStateChanged = pyqtSignal(bool, arguments=['recState'])
    beforeSetCurrentImageProperty = pyqtSignal(int, arguments=['index'])
    stillCaptured = pyqtSignal()
    currentImagePropChanged = pyqtSignal(int, arguments=['index'])
    audioVolumeChanged = pyqtSignal(int, arguments=['volume'])
    muteChanged = pyqtSignal(bool, arguments=['muteFlag'])
    histogramSelectionModeChanged = pyqtSignal(int, int, arguments=['cameraIndex', 'mode'])
    histogramSelectionColorChanged = pyqtSignal(int, str, arguments=['cameraIndex', 'color'])
    histogramWindowsVisibleChanged = pyqtSignal()

    def __init__(self, network_camera_model: NetworkCameraModel | None = None,
                 histogram_manager=None, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._engine = None
        self.fbos: list[FramebufferObject] = []
        self.cameras: list[CameraContext] = []
        self.selected_device_type = ""
        self.selected_dev_count = 0
        self.burst_count = 1
        self.folder_path = ""
        self.video_folder_path = ""
        self.video_file_name = ""
        self.still_file_name = ""
        self.timestamp = ""
        self._histogram_windows_visible = False
        self._audio_lock = threading.Lock()
        self._audio_device_open = False
        self.audio_device_connected = False
        self.audio_device_index = -1
        self.audio_device_path = ""
        self.audio_volume = 100.0
        self.audio_muted = False

        self._network_model = network_camera_model or NetworkCameraModel()
        self._connect_network_model(self._network_model)

        if histogram_manager is None:
            from camvistra.histogram import HistogramManager
            histogram_manager = HistogramManager()
        self.histogram = histogram_manager
        self.histogram.histogramSelectionModeChanged.connect(self.histogramSelectionModeChanged)
        self.histogram.histogramSelectionColorChanged.connect(self.histogramSelectionColorChanged)
        self.histogram.histogramWindowVisibilityChanged.connect(self._set_histogram_windows_visible)

        self._recording_thread = RecordingThread()
        self._recording_thread.start()

        # Latency samples are collected natively by each FramePump (one per
        # displayed frame) and handed to diagnostics in batches, so the
        # per-frame callback does no diagnostics work in Python.
        self._latency_timer = QTimer(self)
        self._latency_timer.setInterval(self.LATENCY_DRAIN_MS)
        self._latency_timer.timeout.connect(self._drain_latency_samples)
        self._latency_timer.start()

    def set_engine(self, engine) -> None:
        """Replacement for the C++ GlobalEngine singleton."""
        self._engine = engine

    def shutdown(self) -> None:
        """C++ destructor: close histogram windows, stop all streams, stop the recorder."""
        self.closeHistogramWindows()
        self._stop_stream()
        self._recording_thread.shutdown()

    # ------------------------------------------------------------------
    # Qt property
    # ------------------------------------------------------------------
    @pyqtProperty(bool, notify=histogramWindowsVisibleChanged)
    def histogramWindowsVisible(self) -> bool:
        return self._histogram_windows_visible

    def _set_histogram_windows_visible(self, visible: bool) -> None:
        if self._histogram_windows_visible == visible:
            tslog.log_info(1, "Histogram visibility was already set")
            return
        self._histogram_windows_visible = visible
        self.histogramWindowsVisibleChanged.emit()
        tslog.log_info(1, "Histogram windows marked visible" if visible else "Histogram windows marked hidden")

    # ------------------------------------------------------------------
    # Layout of the preview grid
    # ------------------------------------------------------------------
    @pyqtSlot(result=int)
    def getFrameCount(self) -> int:
        count = len(self.fbos)
        tslog.log_info(count, "Framebuffer count retrieved")
        return count

    def _valid_fbo(self, index: int) -> bool:
        return 0 <= index < len(self.fbos)

    @pyqtSlot(int, int, result=int)
    def getFrameWidth(self, index: int, width: int) -> int:
        total = len(self.fbos)
        if not self._valid_fbo(index):
            return tslog.log_result(0, False, "Invalid framebuffer index")
        frame_width = _cdiv(width, total) if total <= 2 else _cdiv(width, (total + 1) // 2)
        tslog.log_info(frame_width, "Frame width calculated")
        return frame_width

    @pyqtSlot(int, int, result=int)
    def getFrameHeight(self, index: int, height: int) -> int:
        total = len(self.fbos)
        if not self._valid_fbo(index):
            return tslog.log_result(0, False, "Invalid framebuffer index")
        frame_height = height if total <= 2 else _cdiv(height, 2)
        tslog.log_info(frame_height, "Frame height calculated")
        return frame_height

    @pyqtSlot(int, int, result=int)
    def getFrameX(self, index: int, width: int) -> int:
        total = len(self.fbos)
        if not self._valid_fbo(index):
            return tslog.log_result(0, False, "Invalid framebuffer index")
        if total <= 2:
            frame_x = index * _cdiv(width, total)
        else:
            columns = (total + 1) // 2
            row = 0 if index < columns else 1
            col = index if row == 0 else index - columns
            items_in_row = columns if row == 0 else total - columns
            cell_width = _cdiv(width, columns)
            row_start = _cdiv(width - items_in_row * cell_width, 2)
            frame_x = row_start + col * cell_width
        tslog.log_info(frame_x, "Frame X position calculated")
        return frame_x

    @pyqtSlot(int, int, result=int)
    def getFrameY(self, index: int, height: int) -> int:
        total = len(self.fbos)
        if not self._valid_fbo(index):
            return tslog.log_result(0, False, "Invalid framebuffer index")
        if total <= 2:
            tslog.log_info(0, "Frame Y position calculated")
            return 0
        row = 0 if index < (total + 1) // 2 else 1
        frame_y = row * _cdiv(height, 2)
        tslog.log_info(frame_y, "Frame Y position calculated")
        return frame_y

    # ------------------------------------------------------------------
    # Framebuffer objects
    # ------------------------------------------------------------------
    @pyqtSlot(result=int)
    def updateFramebufferObject(self) -> int:
        engine = self._engine
        if engine is None:
            return tslog.log_result(0, False, "QML engine is unavailable")
        roots = engine.rootObjects()
        if not roots:
            return tslog.log_result(0, False, "QML root object list is empty")
        root = roots[0]
        if root is None:
            return tslog.log_result(0, False, "QML root object is unavailable")
        repeater = root.findChild(QObject, "fboRepeater")
        if repeater is None:
            return tslog.log_result(0, False, "FBO repeater is unavailable")
        if not isinstance(repeater, QQuickItem):
            return tslog.log_result(0, False, "FBO repeater item is invalid")
        found = []
        for i in range(int(repeater.property("count") or 0)):
            container = QMetaObject.invokeMethod(repeater, "itemAt", Qt.DirectConnection,
                                                 Q_RETURN_ARG(QQuickItem), Q_ARG(int, i))
            if container is None:
                continue
            fbo = container.findChild(FramebufferObject)
            if fbo is not None:
                found.append(fbo)
        if not found:
            return tslog.log_result(0, False, "No framebuffer objects were found")
        self.fbos = found
        # Running pumps follow the QML-owned items (C++ indexes fbos[] live).
        for i, cam in enumerate(self.cameras):
            if cam is not None and cam.pump is not None and i < len(self.fbos):
                cam.pump.slot = self.fbos[i].slot
        return tslog.log_result(1, True, "Framebuffer objects updated")

    def _initialize_fbo(self) -> int:
        for fbo in self.fbos:
            fbo.stopFrame()
            fbo.cleanOpenGLDisplay()
        self.fbos = [FramebufferObject() for _ in range(self.selected_dev_count)]
        if self.fbos:
            self.fboCreated.emit()
        return tslog.log_result(1, True, "Framebuffer objects initialized")

    # ------------------------------------------------------------------
    # Stream threads
    # ------------------------------------------------------------------
    def _diag_key(self, index: int) -> str:
        return f"USB:{index}" if self.selected_device_type == "Usb" else f"Network:{index}"

    def _start_threads(self, index: int) -> None:
        cam = self.cameras[index]
        source = cam.usb_model.camera if cam.usb_model is not None else cam.net_model.stream
        slot = self.fbos[index].slot if index < len(self.fbos) else sdk.FrameSlot()
        if cam.pump is None:
            pump = sdk.FramePump(source, slot, cam.capture, cam.usb_model is None)
            pump.onInitialized = self._on_stream_initialized
            pump.onFrame = self._on_frame
            cam.attach_pump(pump)
        else:
            cam.pump.slot = slot
        cam.pump.index = index
        cam.pump.start()
        cam.still_thread = threading.Thread(target=self._still_capture, args=(cam,),
                                            name=f"StillCapture-{index}", daemon=True)
        cam.still_thread.start()

    def _join_threads(self, cam: CameraContext) -> None:
        if cam.pump is not None:
            cam.pump.join()
        if cam.still_thread is not None:
            cam.still_thread.join()
            cam.still_thread = None

    def _signal_stop(self, cam: CameraContext) -> None:
        if cam.pump is not None:
            cam.pump.signalStop()

    # Called from the native processing thread.
    # The pump has just stored the first frame's width/height/pixel format
    # (only outside a cross still capture, as in C++ processFrames).
    def _on_stream_initialized(self, index: int) -> None:
        cam = self._cam(index)
        pump = cam.pump if cam is not None else None
        if pump is not None:
            # Metadata from the first received frame: some CSI/V4L2 drivers
            # cannot answer the separate format ioctl.
            self.formatChanged.emit(index, pump.pixelValue)
            self.resolutionChanged.emit(index, f"{pump.width}x{pump.height}")
        self.cameraOpened.emit(index)
        self.centerStatusChanged.emit("Streaming initialized")

    # Called from the native processing thread once per displayed frame, with
    # the GIL taken: keep it to the repaint request and the (rate-limited)
    # histogram hand-off.
    def _on_frame(self, index: int, capture_ts_ms: int) -> None:
        fbos = self.fbos
        if index >= len(fbos):
            return
        fbo = fbos[index]
        fbo.request_update()
        self.histogram.push_frame_from_slot(index, fbo.slot)

    LATENCY_DRAIN_MS = 500

    def _drain_latency_samples(self) -> None:
        """GUI thread: forward the latency samples each pump collected since the
        last call (always taken, so they don't pile up without a session)."""
        manager = None
        for index, cam in enumerate(self.cameras):
            pump = cam.pump if cam is not None else None
            if pump is None:
                continue
            samples = pump.takeLatencySamples()
            if not samples or not feature_flags.DIAGNOSTICS_ENABLED:
                continue
            if manager is None:
                try:
                    from camvistra.diagnostics import DiagnosticsManager
                except ImportError:  # pragma: no cover - diagnostics optional in unit tests
                    return
                manager = DiagnosticsManager.instance()
            manager.report_latency_samples(self._diag_key(index), samples)

    def _stop_stream(self) -> int:
        self.histogram.destroy_all()
        self._set_histogram_windows_visible(False)
        for i in range(len(self.fbos) - 1, -1, -1):
            if i >= len(self.cameras) or self.cameras[i] is None:
                continue
            cam = self.cameras[i]
            self.formatChanged.emit(i, "")
            self.resolutionChanged.emit(i, "")
            self.fbos[i].stopFrame()
            self._signal_stop(cam)
            if self.selected_device_type in ("Wi-Fi", "Ethernet") and cam.net_model is not None:
                cam.net_model.request_stop()
            cam.capture.set(False)
            cam.is_buffer_initialized = False
            self._join_threads(cam)
            self.fbos[i].cleanOpenGLDisplay()
        self.fbos = []
        # Slots without an FBO (e.g. a Wi-Fi camera opened before the preview
        # surface exists) still run threads that must be joined.
        for i in range(len(self.cameras)):
            self._stop_camera_threads(i)
        self._reset_still_capture_state()
        return 1

    def _stop_camera_threads(self, index: int) -> None:
        """C++ stopCameraThreads: stop and join one slot's threads."""
        cam = self._cam(index)
        if cam is None:
            return
        self._signal_stop(cam)
        if cam.net_model is not None:
            cam.net_model.request_stop()  # unblocks a pending GetFrame
        self._join_threads(cam)

    def _reset_still_capture_state(self) -> None:
        self.burst_count = 1
        for cam in self.cameras:
            if cam is None:
                continue
            cam.capture.set(False)
            cam.is_cross_still_capture = False
            cam.is_set_image_property = False
            cam.still_width = 0
            cam.still_height = 0
            cam.still_fps = 0
            cam.still_pixel_value = ""
            cam.still_file_fmt = ""

    def _stop_preview_stream(self, index: int) -> int:
        self.histogram.destroy_histogram_window(index)
        self.fbos[index].stopFrame()
        self.formatChanged.emit(index, "")
        self.resolutionChanged.emit(index, "")
        cam = self.cameras[index]
        self._signal_stop(cam)
        cam.capture.set(False)
        cam.is_buffer_initialized = False
        self._join_threads(cam)
        self.fbos[index].cleanOpenGLDisplay()
        return 1

    def _start_preview_stream(self, index: int) -> int:
        self._start_threads(index)
        self.fbos[index].startStream()
        self.currentImagePropChanged.emit(index)
        return 1

    @pyqtSlot(int, result=int)
    def restartPreviewStream(self, index: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None \
                or self.cameras[index].usb_model is None:
            return 0
        if not self.cameras[index].streaming:
            return 0
        self._stop_preview_stream(index)
        return self._start_preview_stream(index)

    # ------------------------------------------------------------------
    # Still capture
    # ------------------------------------------------------------------
    def _get_timestamp(self) -> str:
        self.timestamp = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
        tslog.log_info(1, "Timestamp generated")
        return self.timestamp

    def _file_label(self, cam: CameraContext) -> str:
        """Camera part of capture/recording file names (C++ fileLabel): the
        device name with characters outside [A-Za-z0-9._-] replaced by a
        single '_'. Cameras sharing a name get their 1-based position among
        them appended so simultaneous captures cannot overwrite each other."""
        label = ""
        for ch in cam.name:
            if _SAFE_FILE_CHAR.fullmatch(ch):
                label += ch
            elif not label or label[-1] != "_":
                label += "_"
        label = label.rstrip("_.").lstrip("_.") or "Camera"
        same = position = 0
        for other in self.cameras:
            if other is not None and other.name == cam.name:
                same += 1
                if other is cam:
                    position = same
        if same > 1:
            label = f"{label}_{position}"
        return label

    def _file_stem(self, cam: CameraContext, timestamp: str | None = None) -> str:
        stamp = self._get_timestamp() if timestamp is None else timestamp
        return f"{CAPTURE_FILE_PREFIX}_{self._file_label(cam)}_{stamp}"

    def _still_capture(self, cam: CameraContext) -> None:
        capture_count = 1
        pump = cam.pump
        while pump.streaming:
            frame = pump.waitCaptureFrame(STILL_WAIT_S)
            if frame is None:
                continue
            start = time.perf_counter()
            if capture_count == self.burst_count:
                cam.capture.set(False)
                capture_count = 1
            else:
                capture_count += 1
            rgb = frame.rgb
            if rgb.size == 0 or rgb.total_size == 0 or rgb.width <= 0 or rgb.height <= 0:
                continue
            if self.selected_device_type == "Usb" and (
                    cam.still_height != rgb.height or cam.still_width != rgb.width
                    or cam.still_pixel_value != rgb.pixel_format):
                continue
            pix = cam.pix_value
            # Y8 is taken from the frame itself: during a cross still capture
            # pix_value still describes the preview format.
            if rgb.pixel_format == "Y8":
                pix = PF.Y8
            elif rgb.pixel_format == "Y12":
                pix = PF.Y12
            w, h = rgb.width, rgb.height
            if pix == PF.Y8:
                expected = w * h
            elif pix == PF.Y12:
                expected = w * h * 3 // 2
            elif pix in (PF.YUYV, PF.UYVY):
                expected = w * h * 2
            elif pix == PF.RGB32:
                expected = w * h * 4
            elif pix in (PF.HEVC, PF.H264, PF.YUV420, PF.NV12):
                expected = w * h * 3 // 2
            else:
                expected = 0
            if expected > 0 and rgb.size < expected:
                continue
            if cam.still_file_fmt == "":
                cam.still_file_fmt = "BMP"
            fmt_upper = cam.still_file_fmt
            ext = {"BMP": ".bmp", "JPEG": ".jpg", "JPG": ".jpg", "PNG": ".png", "RAW": ".raw"}.get(fmt_upper, ".bmp")
            still_file_name = f"{self.folder_path}{os.sep}{self._file_stem(cam)}_{capture_count}{ext}"
            self.still_file_name = still_file_name
            rgb_buff = None
            if fmt_upper != "RAW":
                convert = {
                    PF.HEVC: (sdk.imaging.yuv420ToRgb, "YUV420 frame converted to RGB", "YUV420 input buffer is null"),
                    PF.H264: (sdk.imaging.yuv420ToRgb, "YUV420 frame converted to RGB", "YUV420 input buffer is null"),
                    PF.YUV420: (sdk.imaging.yuv420ToRgb, "YUV420 frame converted to RGB", "YUV420 input buffer is null"),
                    PF.NV12: (sdk.imaging.nv12ToRgb, "NV12 frame converted to RGB",
                              "NV12 input or RGB output buffer is invalid"),
                    PF.RGB32: (sdk.imaging.rgb32ToRgb24, "RGB32 frame converted to RGB24",
                               "RGB frame dimensions are invalid"),
                    PF.UYVY: (sdk.imaging.uyvyToRgb, "UYVY frame converted to RGB",
                              "UYVY input or RGB output buffer is null"),
                    PF.YUYV: (sdk.imaging.yuyvToRgb, "YUYV frame converted to RGB", "YUYV conversion input is invalid"),
                    PF.Y8: (sdk.imaging.y8ToRgb, "Y8 frame converted to RGB", "Y8 conversion input is invalid"),
                    PF.Y12: (sdk.imaging.y12ToRgb, "Y12 frame converted to RGB", "Y12 conversion input is invalid"),
                }.get(pix)
                if convert is None:
                    self.centerStatusChanged.emit("Still capture failed: unsupported pixel format")
                    continue
                fn, ok_msg, fail_msg = convert
                rgb_buff = fn(rgb, w, h)
                tslog.log_result(1 if rgb_buff is not None else 0, rgb_buff is not None,
                                 ok_msg if rgb_buff is not None else fail_msg)
                if rgb_buff is None:
                    self.centerStatusChanged.emit("Still capture failed: conversion error")
                    continue
            save_ok = self._save_still(fmt_upper, still_file_name, rgb_buff, rgb, w, h)
            if not save_ok:
                self.centerStatusChanged.emit(f"Still capture failed: {fmt_upper} save error")
                continue
            elapsed = time.perf_counter() - start
            self.stillCaptured.emit()
            self.centerStatusChanged.emit(f"Still captured in {elapsed:.3f}s")

    @staticmethod
    def _save_still(fmt: str, path: str, rgb_buff, raw, w: int, h: int) -> bool:
        im = sdk.imaging
        if fmt == "BMP":
            ok = im.saveBMP(path, rgb_buff, w, h)
            return tslog.log_bool_result(ok, "BMP image saved" if ok else "BMP file could not be opened")
        if fmt == "PNG":
            ok = im.savePNG(path, rgb_buff, w, h)
            return tslog.log_bool_result(ok, "PNG image saved" if ok else "PNG file could not be opened")
        if fmt == "RAW":
            ok = im.saveRAW(path, raw)
            return tslog.log_bool_result(ok, "RAW image saved" if ok else "RAW file could not be opened")
        if fmt in ("JPEG", "JPG"):
            ok, error = im.saveJPEG(path, rgb_buff, w, h)
            return tslog.log_bool_result(ok, "JPEG image saved" if ok else error)
        return False

    @pyqtSlot(int, result=int)
    def setCaptureFlag(self, index: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return tslog.log_result(0, False, "Invalid camera index for still capture")
        cam = self.cameras[index]
        if (cam.width != cam.still_width or cam.height != cam.still_height
                or cam.still_pixel_value != cam.pixel_value) and self.selected_device_type == "Usb":
            cam.is_cross_still_capture = True
            self.setCurrentImageProperty(index, cam.still_pixel_value,
                                         f"{cam.still_width}x{cam.still_height}", f"{cam.still_fps}fps")
        cam.capture.set(True)
        return 1

    @pyqtSlot(result=int)
    def captureAllCameras(self) -> int:
        """Still capture on every streaming camera; each camera has its own
        capture flag and still thread, so they capture independently."""
        armed = sum(1 for i, cam in enumerate(self.cameras)
                    if cam is not None and cam.streaming and self.setCaptureFlag(i) == 1)
        return tslog.log_result(1 if armed > 0 else 0, armed > 0, f"Still capture requested on {armed} camera(s)")

    @pyqtSlot(int, result=str)
    def cameraName(self, index: int) -> str:
        """Device name of the camera in slot ``index`` (shown on its preview
        tile); empty for an invalid or empty slot."""
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return ""
        return self.cameras[index].name

    @pyqtSlot(int, result=int)
    def getFileDescriptorForCamera(self, index: int) -> int:
        """Open descriptor of the camera in slot ``index``, or -1."""
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None \
                or self.cameras[index].usb_model is None:
            return -1
        return self.cameras[index].usb_model.get_file_descriptor_value()

    # Read by the shared QML to enable capture/record with several cameras.
    @pyqtProperty(bool, constant=True)
    def multiCameraCapture(self) -> bool:
        return True

    @pyqtSlot(int, result=int)
    def setBurstLength(self, length: int) -> int:
        if length > 0:
            self.burst_count = length
            return tslog.log_result(1, True, "Burst length set")
        return tslog.log_result(0, False, "Burst length must be greater than zero")

    @pyqtSlot(str, result=int)
    def setStillFolderPath(self, folder: str) -> int:
        self.folder_path = folder
        return tslog.log_result(1, True, "Still-capture folder path set")

    @pyqtSlot(str, result=int)
    def setVideoFolderPath(self, folder: str) -> int:
        self.video_folder_path = folder
        return tslog.log_result(1, True, "Video folder path set")

    # ------------------------------------------------------------------
    # Viewport / zoom
    # ------------------------------------------------------------------
    def _calculate_view_port(self, index: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return 0
        cam = self.cameras[index]
        if cam.width <= 0 or cam.height <= 0 or cam.viewport_width <= 0 or cam.viewport_height <= 0:
            return 0
        content = _f32(_f32(cam.width) / _f32(cam.height))
        viewport = _f32(_f32(cam.viewport_width) / _f32(cam.viewport_height))
        if viewport > content:
            cam.view_port_h = cam.viewport_height
            cam.view_port_w = _lround(cam.viewport_height * content)
        else:
            cam.view_port_h = _lround(cam.viewport_width / content)
            cam.view_port_w = cam.viewport_width
        cam.x = _cdiv(cam.viewport_width - cam.view_port_w, 2)
        cam.y = _cdiv(cam.viewport_height - cam.view_port_h, 2)
        return 1

    @pyqtSlot(int, int, int, result=int)
    def setViewPort(self, index: int, width: int, height: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return 0
        cam = self.cameras[index]
        cam.viewport_width, cam.viewport_height = width, height
        if self._calculate_view_port(index) != 1:
            return 0
        self.viewPortChanged.emit(index, cam.x, cam.y, cam.view_port_w, cam.view_port_h)
        tslog.log_info(0, "Viewport set")
        return 1

    @pyqtSlot(int, int, int, float, result=int)
    def applyZoom(self, index: int, viewportW: int, viewportH: int, zoomFactor: float) -> int:
        zoom = _f32(zoomFactor)
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None \
                or viewportW <= 0 or viewportH <= 0 or zoom <= 0.0:
            return tslog.log_result(0, False, "Zoom input is invalid")
        cam = self.cameras[index]
        scaled_w, scaled_h = int(_f32(viewportW * zoom)), int(_f32(viewportH * zoom))
        cam.viewport_width, cam.viewport_height = scaled_w, scaled_h
        if self._calculate_view_port(index) != 1:
            return tslog.log_result(0, False, "Zoom viewport calculation failed")
        if zoom > 1.0:
            cam.x = cam.y = 0
            cam.view_port_w, cam.view_port_h = scaled_w, scaled_h
        self.viewPortChanged.emit(index, cam.x, cam.y, cam.view_port_w, cam.view_port_h)
        return tslog.log_result(1, True, "Zoom applied")

    # ------------------------------------------------------------------
    # Opening / closing cameras
    # ------------------------------------------------------------------
    def _connect_network_model(self, model: NetworkCameraModel) -> None:
        for name in ("cameraOpened", "cameraClosed", "devicesUpdated", "fpsChanged",
                     "resolutionChanged", "formatChanged", "recordingStateChanged"):
            getattr(model, name).connect(getattr(self, name))

    def _connect_usb_model(self, model: UsbCameraModel) -> None:
        for name in ("cameraOpened", "cameraClosed", "devicesUpdated", "fpsChanged", "resolutionChanged",
                     "formatChanged", "statusChanged", "cameraControlProperty", "imagePropertiesMapChanged",
                     "currentImagePropertyChanged", "fileDescriptor", "defaultUiValues",
                     "recordingStateChanged", "audioVolumeChanged", "muteChanged"):
            getattr(model, name).connect(getattr(self, name))

    def _open_camera(self, index: int, source: str, friendly_name: str = "") -> int:
        if self._cam(index) is None:
            return 0
        cam = self.cameras[index]
        # Destroy any stale model only after its threads have stopped using it.
        if cam.net_model is not None:
            self._stop_camera_threads(index)
            cam.net_model.close_camera(index)
            cam.net_model = None
            cam.pump = None
        cam.net_model = NetworkCameraModel()
        cam.net_model.set_diagnostics_session_key(f"Network:{index}")
        cam.net_model.set_diagnostics_camera_name(friendly_name)
        self._connect_network_model(cam.net_model)
        if cam.net_model.open_camera(source) == 1:
            cam.net_model.register_dev_callback(index)
            cam.name = friendly_name or source
            self._start_threads(index)
            self.centerStatusChanged.emit("Device initialized")
            return 1
        return 0

    def _open_usb_camera(self, index: int, source: str, friendly_name: str = "") -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return 0
        cam = self.cameras[index]
        if cam.usb_model is not None:
            cam.usb_model.close_camera(index)
            cam.usb_model = None
            cam.pump = None
        cam.usb_model = UsbCameraModel()
        cam.usb_model.set_diagnostics_session_key(f"USB:{index}")
        cam.usb_model.set_diagnostics_camera_name(friendly_name)
        self._connect_usb_model(cam.usb_model)
        if cam.usb_model.open_camera(source) == 1:
            cam.device_path = source
            cam.name = friendly_name or source
            self._start_threads(index)
            return 1
        return 0

    def _close_camera(self, index: int) -> int:
        cam = self.cameras[index]
        if cam.net_model is not None:
            self.histogram.destroy_histogram_window(index)
            return cam.net_model.close_camera(index)
        return 0

    def _close_usb_camera(self, index: int) -> int:
        cam = self.cameras[index]
        if cam.usb_model is not None:
            self.histogram.destroy_histogram_window(index)
            return cam.usb_model.close_camera(index)
        return 0

    def _new_context(self) -> CameraContext:
        return CameraContext(capture=sdk.CaptureFlag())

    @pyqtSlot("QVariantMap", result=int)
    def addSelectedUsbDevice(self, device: dict) -> int:
        source = str(device.get("srcUrl", "") or "")
        if not source:
            return tslog.log_result(0, False, "addSelectedUsbDevice: empty source url")
        friendly = str(device.get("deviceName", "") or "")
        if len(self.cameras) >= MAX_CAMERAS:
            return tslog.log_result(0, False, "addSelectedUsbDevice: max camera count reached")
        new_index = len(self.cameras)
        self.cameras.append(self._new_context())
        if self._open_usb_camera(new_index, source, friendly) != 1:
            self.cameras.pop()
            return tslog.log_result(0, False, "addSelectedUsbDevice: openUsbCamera failed")
        self.selected_device_type = "Usb"
        self.selected_dev_count = len(self.cameras)
        self.usbDeviceAdded.emit(new_index)
        return tslog.log_result(1, True, "USB device added incrementally")

    @pyqtSlot(str, result=int)
    def removeSelectedUsbDevice(self, devicePath: str) -> int:
        idx = next((i for i, c in enumerate(self.cameras) if c is not None and c.device_path == devicePath), -1)
        if idx < 0:
            return tslog.log_result(0, False, "removeSelectedUsbDevice: device not found")
        with self._audio_lock:
            if idx == 0 and self._audio_device_open and self.cameras[0].usb_model is not None:
                self.cameras[0].usb_model.close_audio_device()
                self._audio_device_open = False
        self.histogram.destroy_histogram_window(idx)
        cam = self.cameras[idx]
        self._signal_stop(cam)
        self._join_threads(cam)
        if cam.usb_model is not None:
            try:
                cam.usb_model.cameraClosed.disconnect(self.cameraClosed)
            except TypeError:
                pass
            cam.usb_model.close_camera(idx)
            cam.usb_model = None
            cam.pump = None
        old_count = len(self.cameras)
        for i in range(idx + 1, old_count):
            self.histogram.destroy_histogram_window(i)
            moved = self.cameras[i]
            self._signal_stop(moved)
            self._join_threads(moved)
            self.cameras[i - 1] = moved
            self._restart_camera_threads(i - 1)
        self.cameras.pop()
        self.selected_dev_count = len(self.cameras)
        self.usbDeviceRemoved.emit(idx, self.selected_dev_count)
        return tslog.log_result(1, True, "USB device removed incrementally")

    def _restart_camera_threads(self, index: int) -> None:
        self._start_threads(index)

    @pyqtSlot(int, str, result=int)
    def setSelectedDeviceCount(self, checkedDevCnt: int, selectedDevType: str) -> int:
        with self._audio_lock:
            if self._audio_device_open and self.cameras and self.cameras[0] is not None \
                    and self.cameras[0].usb_model is not None:
                self.cameras[0].usb_model.close_audio_device()
                self._audio_device_open = False
        index = -1
        self._stop_stream()
        if self.selected_device_type == "Usb":
            index = 0
            while index < self.selected_dev_count and index < len(self.cameras) \
                    and self.cameras[index] is not None and self.cameras[index].usb_model is not None:
                self._close_usb_camera(index)
                index += 1
        elif self.selected_device_type in ("Wi-Fi", "Ethernet"):
            index = 0
            while index < self.selected_dev_count and index < len(self.cameras) \
                    and self.cameras[index] is not None and self.cameras[index].net_model is not None:
                self._close_camera(index)
                index += 1
        if self.selected_dev_count >= 0 and index == self.selected_dev_count:
            self.cameraClosed.emit()
            self.cameras = []
        self.cameras = [self._new_context() for _ in range(checkedDevCnt)]
        self.selected_device_type = selectedDevType
        self.selected_dev_count = checkedDevCnt
        return 1

    @pyqtSlot("QVariantList", result=int)
    def setSelectedDevices(self, selectedDevices: list) -> int:
        requested_type = ""
        if selectedDevices:
            requested_type = str((selectedDevices[0] or {}).get("deviceType", "") or "")
        for i in range(min(self.selected_dev_count, len(self.cameras))):
            cam = self.cameras[i]
            if cam is None:
                continue
            self._signal_stop(cam)
            if self.selected_device_type in ("Wi-Fi", "Ethernet") and cam.net_model is not None:
                cam.net_model.request_stop()
            self._join_threads(cam)
            if self.selected_device_type == "Usb":
                if cam.usb_model is not None:
                    cam.usb_model.close_camera(i)
                    cam.usb_model = None
            elif self.selected_device_type in ("Wi-Fi", "Ethernet"):
                if cam.net_model is not None:
                    cam.net_model.close_camera(i)
                    cam.net_model = None
        self._stop_stream()
        if requested_type:
            self.selected_device_type = requested_type
        self.selected_dev_count = len(selectedDevices)
        self.cameras = [self._new_context() for _ in range(self.selected_dev_count)]
        self._initialize_fbo()
        if self.selected_device_type == "Usb":
            for index, dev in enumerate(selectedDevices):
                dev = dev or {}
                self._open_usb_camera(index, str(dev.get("srcUrl", "") or ""), str(dev.get("deviceName", "") or ""))
            with self._audio_lock:
                if (self.audio_device_connected and self.audio_device_index >= 0 and self.cameras
                        and self.cameras[0].usb_model is not None
                        and self.cameras[0].usb_model.supports_audio() and not self._audio_device_open):
                    self.cameras[0].usb_model.open_audio_device(self.audio_device_path, self.audio_device_index)
                    self._audio_device_open = True
                    self.getAudioRange()
                    self.getMute()
            return 1
        if self.selected_device_type in ("Wi-Fi", "Ethernet"):
            for index, dev in enumerate(selectedDevices):
                dev = dev or {}
                self._open_camera(index, str(dev.get("srcUrl", "") or ""), str(dev.get("deviceName", "") or ""))
            return 1
        return 0

    # ------------------------------------------------------------------
    # Recording
    # ------------------------------------------------------------------
    def _recording_models(self) -> list[tuple[CameraContext, object, object]]:
        usb = self.selected_device_type == "Usb"
        out = []
        for cam in self.cameras:
            if cam is None:
                continue
            model = cam.usb_model if usb else cam.net_model
            if model is not None:
                out.append((cam, model if usb else None, None if usb else model))
        return out

    @pyqtSlot(result=int)
    def startVideoRecording(self) -> int:
        """Records every open camera, one file per camera."""
        stamp = self._get_timestamp()  # one timestamp shared by every camera's file
        jobs = [(f"{self.video_folder_path}/{self._file_stem(cam, stamp)}.mp4", usb, net)
                for cam, usb, net in self._recording_models()]
        if not jobs:
            return tslog.log_result(0, False, "No camera available for recording")
        self.video_file_name = jobs[0][0]
        self._recording_thread.worker().start_recordings(jobs)
        return 1  # the result is signalled later

    @pyqtSlot(result=int)
    def stopRecording(self) -> int:
        models = [(usb, net) for _, usb, net in self._recording_models()]
        if not models:
            return 0
        self._recording_thread.worker().stop_recordings(models)
        return 1

    # ------------------------------------------------------------------
    # Stream information / UVC controls
    # ------------------------------------------------------------------
    @pyqtSlot(int, result=int)
    def getFps(self, index: int) -> int:
        cam = self._cam(index)
        if cam is None:
            return 0
        if self.selected_device_type == "Usb":
            return cam.usb_model.get_current_framerate(index) if cam.usb_model is not None else 0
        return cam.net_model.get_current_framerate(index) if cam.net_model is not None else 0

    @pyqtSlot(int, result=int)
    def getStreamFormat(self, index: int) -> int:
        if self.selected_dev_count <= 0:
            return 0
        cam = self._cam(index)
        if cam is None:
            return 0
        if self.selected_device_type == "Usb":
            if cam.usb_model is None:
                return 0
            if cam.still_width == 0 and cam.still_height == 0:
                self.getCurrentStillProperty(index)
            return cam.usb_model.get_current_stream_format(index)
        if cam.net_model is None:
            return 0
        return cam.net_model.get_current_stream_format(index)

    @pyqtSlot(result=bool)
    def readUsbJsonArrayFile(self) -> bool:
        data = read_qrc_json(":/View/JSON/usbProperty.json")
        if data is None:
            return tslog.log_bool_result(False, "USB property JSON could not be opened or parsed")
        if not isinstance(data, list):
            return tslog.log_bool_result(False, "USB property JSON root is not an array")
        self.jsonArrayRead.emit(data)
        return tslog.log_bool_result(True, "USB property JSON loaded")

    @pyqtSlot(str, str, result=bool)
    def readExtensionUsbJsonArrayFile(self, vid: str, pid: str) -> bool:
        name = DeviceEnums.json_file_name_from_vid_pid(vid, pid) or "NoAvailableExtension"
        path = f":/View/JSON/{name}.json"
        if not QFile.exists(path):
            path = ":/View/JSON/NoAvailableExtension.json"
            if not QFile.exists(path):
                return tslog.log_bool_result(False, "Extension JSON and fallback could not be opened")
        data = read_qrc_json(path)
        if data is None:
            return tslog.log_bool_result(False, "Extension JSON parsing failed")
        if not isinstance(data, list):
            return tslog.log_bool_result(False, "Extension JSON root is not an array")
        self.extensionJsonArrayRead.emit(data)
        return tslog.log_bool_result(True, "Extension JSON loaded")

    def _cam(self, index: int):
        """Camera slot ``index``, or None for an invalid index or empty slot
        (QML can still use the index of a camera that was just unplugged)."""
        if not (0 <= index < len(self.cameras)):
            return None
        return self.cameras[index]

    def _usb(self, index: int):
        cam = self._cam(index)
        return cam.usb_model if cam is not None else None

    @pyqtSlot(int, int, result=int)
    def getCameraControlProperty(self, index: int, controlId: int) -> int:
        usb = self._usb(index)
        return usb.get_camera_control_property(controlId) if usb is not None else 0

    @pyqtSlot(int, result=int)
    def getCurrentImageProperty(self, index: int) -> int:
        usb = self._usb(index)
        return usb.get_current_image_property() if usb is not None else 0

    @pyqtSlot(int, result=int)
    def getImageProperty(self, index: int) -> int:
        usb = self._usb(index)
        return usb.get_image_property() if usb is not None else 0

    @pyqtSlot(int, result=int)
    def getFileDescriptor(self, index: int) -> int:
        usb = self._usb(index)
        return usb.get_file_descriptor() if usb is not None else 0

    @pyqtSlot(int, str, int, result=int)
    def setCameraControlProperty(self, index: int, controlId: str, value: int) -> int:
        usb = self._usb(index)
        if usb is None:
            return tslog.log_result(0, False, "Camera is not available for control change")
        return 1 if usb.set_camera_control_property(controlId, value) == 1 else 0

    @pyqtSlot(int, str, str, str, result=int)
    def setCurrentImageProperty(self, index: int, format: str, resolution: str, fps: str) -> int:  # noqa: A002
        cam = self._cam(index)
        if cam is None or cam.usb_model is None:
            return 0
        self.beforeSetCurrentImageProperty.emit(index)
        self._stop_preview_stream(index)
        size = _parse_resolution(resolution) or [1920, 1080]
        prop = {"Compression": format.encode("utf-8")[:7].decode("utf-8", "ignore"),
                "width": size[0], "height": size[1], "fps": float(_strip_fps(fps)), "isNV12Decoded": False}
        if cam.usb_model.set_current_image_property(prop) == 1:
            cam.is_set_image_property = True
            if not cam.is_cross_still_capture:
                cam.fps = int(prop["fps"])
                cam.width, cam.height = prop["width"], prop["height"]
                cam.pixel_value = prop["Compression"]
            self.statusChanged.emit("Video Property updated successfully")
            return self._start_preview_stream(index)
        self.setImagePropertyFailed.emit(index)
        return 0

    @pyqtSlot(int, result=int)
    def setDefaultValues(self, index: int) -> int:
        usb = self._usb(index)
        if usb is None:
            return 0
        return 1 if usb.set_default_values() == 1 else 0

    @pyqtSlot(int, result=int)
    def getCurrentStillProperty(self, index: int) -> int:
        cam = self._cam(index)
        if cam is None or cam.usb_model is None:
            return 0
        cam.is_cross_still_capture = False
        res, prop = cam.usb_model.get_current_still_image_property()
        if res == 1:
            cam.still_pixel_value = prop["Compression"][:7]
            cam.still_fps = int(prop["fps"])
            cam.fps = int(prop["fps"])
            cam.still_width, cam.still_height = prop["width"], prop["height"]
            cam.still_file_fmt = "BMP"
            return 1
        return 0

    @pyqtSlot(int, str, str, str, str, result=int)
    def setCurrentStillProperty(self, index: int, format: str, resolution: str, fps: str,  # noqa: A002
                                fileFormat: str) -> int:
        cam = self._cam(index)
        if cam is None or cam.usb_model is None:
            return 0
        cam.still_pixel_value = format.encode("utf-8")[:7].decode("utf-8", "ignore")
        cam.still_file_fmt = fileFormat.encode("utf-8")[:4].decode("utf-8", "ignore")
        size = _parse_resolution(resolution)
        if size is not None:
            cam.still_width, cam.still_height = size
        cam.still_fps = _strip_fps(fps)
        self.statusChanged.emit("Still property updated successfully")
        return 1

    @pyqtSlot(int, result=int)
    def resumeVideoStream(self, index: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return 0
        cam = self.cameras[index]
        if not cam.capture.get() and cam.is_cross_still_capture:
            self.setCurrentImageProperty(index, cam.pixel_value, f"{cam.width}x{cam.height}", f"{cam.fps}fps")
            cam.is_cross_still_capture = False
        return 1

    # ------------------------------------------------------------------
    # Histogram
    # ------------------------------------------------------------------
    @pyqtSlot(int, result=int)
    def showHistogramWindow(self, index: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return tslog.log_result(0, False, "Invalid camera index for histogram window")
        if not self.cameras[index].streaming:
            return tslog.log_result(0, False, "Camera is not streaming")
        self.histogram.create_histogram_window(index, self.cameras[index].name)
        self._set_histogram_windows_visible(True)
        return tslog.log_result(1, True, "Histogram window shown")

    @pyqtSlot(result=int)
    def closeHistogramWindows(self) -> int:
        self.histogram.destroy_all()
        self._set_histogram_windows_visible(False)
        return tslog.log_result(1, True, "Histogram windows closed")

    @pyqtSlot(int, int, int, int, int, int, int, int, result=int)
    def setHistogramSelection(self, index: int, mode: int, x: int, y: int, width: int, height: int,
                              previewWidth: int, previewHeight: int) -> int:
        if not (0 <= index < len(self.cameras)) or self.cameras[index] is None:
            return tslog.log_result(0, False, "Invalid camera index for histogram selection")
        fw, fh = self.cameras[index].width, self.cameras[index].height
        if fw <= 0 or fh <= 0 or previewWidth <= 0 or previewHeight <= 0:
            return tslog.log_result(0, False, "Histogram selection dimensions are invalid")
        from camvistra.histogram import HistogramSelection
        sel = HistogramSelection()
        sel.mode = mode
        sel.x = _clamp(_cdiv(x * fw, previewWidth), 0, fw - 1)
        sel.y = _clamp(_cdiv(y * fh, previewHeight), 0, fh - 1)
        sel.width = _clamp(_cdiv(width * fw, previewWidth), 1, fw - sel.x)
        sel.height = _clamp(_cdiv(height * fh, previewHeight), 1, fh - sel.y)
        self.histogram.set_histogram_selection(index, sel)
        return 1

    @pyqtSlot(result=int)
    def toggleSelectedHistogramWindows(self) -> int:
        count = self.selected_dev_count
        if any(self.histogram.has_histogram_window(i) for i in range(count)):
            for i in range(count):
                self.histogram.destroy_histogram_window(i)
            self._set_histogram_windows_visible(False)
            return tslog.log_result(1, True, "Selected histogram windows closed")
        opened_any = False
        for i in range(count):
            if i >= len(self.cameras) or self.cameras[i] is None or not self.cameras[i].streaming:
                continue
            self.histogram.create_histogram_window(i, self.cameras[i].name)
            opened_any = True
        self._set_histogram_windows_visible(opened_any)
        return tslog.log_result(1 if opened_any else 0, opened_any,
                                "Selected histogram windows opened" if opened_any
                                else "No streaming camera available for histogram")

    # ------------------------------------------------------------------
    # Audio
    # ------------------------------------------------------------------
    def _first_usb(self):
        if not self.cameras or self.cameras[0] is None:
            return None
        return self.cameras[0].usb_model

    @pyqtSlot(str, int, result=int)
    def setSelectedAudioDevice(self, devicePath: str, deviceIndex: int) -> int:
        with self._audio_lock:
            usb = self._first_usb()
            if not devicePath:
                self.audio_device_connected = False
                self.audio_device_index = -1
                self.audio_device_path = ""
                if usb is not None and self._audio_device_open:
                    usb.close_audio_device()
                    self._audio_device_open = False
                return 0
            self.audio_device_connected = True
            self.audio_device_index = deviceIndex
            self.audio_device_path = devicePath
            if usb is not None and not self._audio_device_open:
                usb.open_audio_device(self.audio_device_path, self.audio_device_index)
                self._audio_device_open = True
                self.getAudioRange()
                self.getMute()
            return 1

    @pyqtSlot(result=int)
    def getAudioRange(self) -> int:
        usb = self._first_usb()
        if usb is None:
            return 0
        res, value = usb.get_audio_range()
        if res == 1:
            self.audio_volume = value * 100.0
            return 1
        return 0

    @pyqtSlot(result=int)
    def getMute(self) -> int:
        usb = self._first_usb()
        if usb is None:
            return 0
        res, value = usb.get_mute()
        if res == 1:
            self.audio_muted = value
            return 1
        return 0

    @pyqtSlot(float, result=int)
    def setAudioRange(self, value: float) -> int:
        self.audio_volume = min(100.0, max(0.0, value))
        usb = self._first_usb()
        if usb is None:
            return 0
        return 1 if usb.set_audio_range(self.audio_volume / 100) == 1 else 0

    @pyqtSlot(bool, result=int)
    def setMute(self, flag: bool) -> int:
        self.audio_muted = flag
        usb = self._first_usb()
        if usb is None:
            return 0
        return 1 if usb.set_mute(flag) == 1 else 0


_SAFE_FILE_CHAR = re.compile(r"[A-Za-z0-9._-]")


def _f32(value: float) -> float:
    """Round to IEEE single precision (C++ float arithmetic)."""
    import struct
    return struct.unpack("f", struct.pack("f", value))[0]


def _lround(value: float) -> int:
    """std::lround: round half away from zero."""
    return int(math.floor(value + 0.5)) if value >= 0 else -int(math.floor(-value + 0.5))


def _cdiv(a: int, b: int) -> int:
    """C++ integer division (truncates toward zero)."""
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b >= 0) else -q
