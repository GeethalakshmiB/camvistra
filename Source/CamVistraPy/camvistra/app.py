"""Application entry point (port of CamVistra/main.cpp).

Startup sequence (same order as the C++ application):
  1. Wayland: force the basic scene-graph render loop (histogram windows),
     run Qt on xcb and match PyOpenGL's platform (GLX/EGL) to Qt's context.
  2. Qt attributes (shared GL contexts, high DPI; desktop GL for PyOpenGL).
  3. Detect Ubuntu 20.04/22.04/24.04; initialise QtWebEngine before or after
     QApplication accordingly; pick QML/ or UB20_QML/.
  4. Register QML types, scan for orphaned diagnostics sessions.
  5. Create models/controllers and expose them as context properties.
  6. Load main.qml, install the Windows title-bar filter, wire
     fboLoaded/viewLoaded, run the event loop, then shut down cleanly.

As in the C++ app, an animated splash screen is shown right after the
QApplication exists. It stays up for at least MINIMUM_DURATION_MS after its
intro, is pumped between the blocking start-up steps so it keeps animating,
and is hidden once the main window has presented its first frame.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from PyQt5.QtCore import QCoreApplication, QDir, QEventLoop, QMetaObject, Qt, QTimer, QUrl
from PyQt5.QtGui import QGuiApplication, QIcon, QImage
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType, qmlRegisterUncreatableType
from PyQt5.QtWidgets import QApplication, QStyle

from camvistra.branding import APP_NAME

IS_WINDOWS = sys.platform == "win32"


def _detect_ubuntu() -> tuple[bool, bool, bool]:
    try:
        content = Path("/etc/os-release").read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False, False, False
    return "20.04" in content, "22.04" in content, "24.04" in content


def _init_webengine() -> None:
    from PyQt5.QtWebEngine import QtWebEngine
    QtWebEngine.initialize()


def register_qml_types() -> None:
    from camvistra.cameras import REGISTRY
    from camvistra.controls.duration_timer import DurationTimer
    from camvistra.controls.opengl_display import FramebufferObject
    from camvistra.device_enums import DeviceEnums
    from camvistra.histogram import register_qml_types as register_histogram_types

    qmlRegisterType(FramebufferObject, "qml.components.frameBufferObject", 1, 0, "FrameBufferObject")
    register_histogram_types()
    qmlRegisterType(DurationTimer, "DurationTimer", 1, 0, "DurationTimer")
    qmlRegisterUncreatableType(DeviceEnums, "DeviceEnums", 1, 0, "DeviceEnums",
                               "Cannot create DeviceEnums in QML")
    for entry in REGISTRY:
        if entry.qml_type:
            qmlRegisterUncreatableType(entry.load(), entry.qml_type, 1, 0, entry.qml_type,
                                       f"{entry.qml_type} is not creatable from QML")


class CamVistraApp:
    """Owns every backend object for the lifetime of the QML engine."""

    def __init__(self, qml_main: str, show_window: bool = True, progress=None) -> None:
        """``show_window=False`` leaves main.qml hidden (it starts with
        ``visible: false``) so the caller can show it after the splash.
        ``progress`` is called between the slow steps to keep the splash
        animating."""
        from camvistra.cameras import REGISTRY
        from camvistra.controllers.about_controller import AboutController
        from camvistra.controllers.device_controller import DeviceController
        from camvistra.controllers.log_controller import LogController
        from camvistra.controllers.preview_controller import PreviewController
        from camvistra.controllers.routecam_onvif_controller import RoutecamOnvifController
        from camvistra.controllers.wifi_onvif_controller import WifiOnvifController
        from camvistra.controls.duration_timer import DurationTimer
        from camvistra.controls.monitor_handler import MonitorHandler
        from camvistra.device_enums import DeviceEnums
        from camvistra.models.device_model import DeviceModel
        from camvistra.models.log_model import LogModel
        from camvistra.models.network_camera_model import NetworkCameraModel
        from camvistra.models.routecam_onvif_model import RoutecamOnvifModel
        from camvistra.models.wifi_onvif_model import WifiOnvifModel

        self.engine = QQmlApplicationEngine()
        ctx = self.engine.rootContext()

        self.device_model = DeviceModel()
        self.wifi_onvif_model = WifiOnvifModel()
        self.routecam_onvif_model = RoutecamOnvifModel()
        self.network_camera_model = NetworkCameraModel()
        self.log_model = LogModel()

        self.duration_timer = DurationTimer()
        self.dev_controller = DeviceController(self.device_model)
        self.wifi_onvif_controller = WifiOnvifController(self.wifi_onvif_model)
        self.routecam_onvif_controller = RoutecamOnvifController(self.routecam_onvif_model)
        self.prev_controller = PreviewController(self.network_camera_model)
        self.about_controller = AboutController()
        self.log_controller = LogController(self.log_model)
        self.device_enums = DeviceEnums()
        self.monitor_handler = MonitorHandler(None)

        self.camera_controllers = {e.context: e.load()() for e in REGISTRY}

        for name, obj in [
            ("durationTimer", self.duration_timer),
            ("devController", self.dev_controller),
            ("wifiOnvifController", self.wifi_onvif_controller),
            ("routecamOnvifController", self.routecam_onvif_controller),
            ("prevController", self.prev_controller),
            ("abtController", self.about_controller),
            ("logController", self.log_controller),
            ("DeviceEnumInstance", self.device_enums),
            *self.camera_controllers.items(),
            ("MonitorHandler", self.monitor_handler),
        ]:
            ctx.setContextProperty(name, obj)

        if not IS_WINDOWS:
            # Save pictures/videos under $HOME instead of the working directory.
            for prop, sub in (("SystemPictureFolder", "Pictures"), ("SystemVideoFolder", "Videos")):
                path = QDir.homePath() + "/" + sub
                QDir().mkpath(path)
                ctx.setContextProperty(prop, "file://" + path)

        if progress is not None:
            progress()
        self.engine.load(QUrl(qml_main))
        self.root = self.engine.rootObjects()[0] if self.engine.rootObjects() else None
        if self.root is None:
            return
        if progress is not None:
            progress()

        self._title_bar_filter = None
        if IS_WINDOWS:
            from camvistra.controls.titlebar import WindowsTitleBarEventFilter
            self._title_bar_filter = WindowsTitleBarEventFilter(self.root)
            self.root.installEventFilter(self._title_bar_filter)

        self.monitor_handler.setWindow(self.root)
        self.monitor_handler.screenInfo()
        self.prev_controller.set_engine(self.engine)

        self.root.fboLoaded.connect(self.prev_controller.updateFramebufferObject)
        self.root.viewLoaded.connect(self.dev_controller.uiComponentLoaded)

        # main.qml starts hidden (visible: false) so it can be shown after the
        # splash screen; without a splash, show it now.
        if show_window:
            QMetaObject.invokeMethod(self.root, "showMainWindow")

    def shutdown(self) -> None:
        from camvistra import feature_flags

        self.dev_controller.shutdown()
        self.prev_controller.shutdown()
        for obj in (self.wifi_onvif_controller, self.routecam_onvif_controller):
            stop = getattr(obj, "shutdown", None)
            if callable(stop):
                stop()
        # Must run while QApplication is alive: finalising a session renders
        # its PDF report with QPdfWriter/QPainter.
        if feature_flags.DIAGNOSTICS_ENABLED:
            from camvistra.diagnostics import DiagnosticsManager
            DiagnosticsManager.instance().shutdown()
        self.log_model.close()


class SplashController:
    """Start-up splash sequencing, as in CamVistra/main.cpp.

    The main window is shown once both the minimum splash time has elapsed
    and the QML root exists; the splash hides on the window's first swapped
    frame, or after 1 s if the platform never reports one.
    """

    def __init__(self, app: QApplication) -> None:
        from camvistra.controls.splash import (
            SPLASH_LOGO, AnimatedSplashScreen, create_splash_pixmap)

        self._app = app
        self._screen = QGuiApplication.primaryScreen()
        logo = QImage(SPLASH_LOGO)
        if logo.isNull():
            from camvistra import tslog
            tslog.log_result(0, False, "Unable to load CamVistra splash logo")
        self.splash = AnimatedSplashScreen(
            self._screen, create_splash_pixmap(), logo,
            Qt.SplashScreen | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        self.splash.setAttribute(Qt.WA_TranslucentBackground, False)
        self.splash.setAttribute(Qt.WA_NoSystemBackground, False)
        self.splash.setAutoFillBackground(True)
        self.splash.setWindowOpacity(1.0)

        self._root = None
        self._quick_window = None
        self._minimum_elapsed = False
        self._main_window_shown = False
        self._min_timer = QTimer()
        self._min_timer.setSingleShot(True)
        self._min_timer.setTimerType(Qt.PreciseTimer)
        self._min_timer.timeout.connect(self._on_minimum_elapsed)

    def _center(self) -> None:
        if self._screen is None:
            return
        self.splash.setGeometry(QStyle.alignedRect(
            Qt.LeftToRight, Qt.AlignCenter, self.splash.size(),
            self._screen.availableGeometry()))

    def start(self) -> None:
        """Show the splash, play the intro, then start the minimum-time timer."""
        from camvistra.controls.splash import INTRO_MS, MINIMUM_DURATION_MS

        # Position the splash before it is mapped and once more right after
        # the window manager has placed it, but before any logo is drawn
        # (opacity 0 at progress 0); re-centering later makes it jump.
        self._center()
        self.splash.show()
        self._app.processEvents(QEventLoop.ExcludeUserInputEvents)
        self._center()
        self.splash.start_animation()
        self._app.processEvents(QEventLoop.ExcludeUserInputEvents)
        intro = QEventLoop()
        QTimer.singleShot(INTRO_MS, intro.quit)
        intro.exec_()
        self._min_timer.start(MINIMUM_DURATION_MS)

    def pump(self) -> None:
        self.splash.pump()

    def set_root(self, root) -> None:
        from PyQt5.QtQuick import QQuickWindow

        self._root = root
        self._quick_window = root if isinstance(root, QQuickWindow) else None
        # The minimum-duration timer may already have fired during start-up.
        self._show_main_window_when_ready()

    def close(self) -> None:
        self._min_timer.stop()
        self.splash.hide()

    def _on_minimum_elapsed(self) -> None:
        self._minimum_elapsed = True
        self._show_main_window_when_ready()

    def _hide_splash(self) -> None:
        self.splash.hide()
        if self._quick_window is not None:
            try:
                self._quick_window.frameSwapped.disconnect(self._hide_splash)
            except TypeError:
                pass  # already disconnected

    def _show_main_window_when_ready(self) -> None:
        if (not self._minimum_elapsed or self._main_window_shown
                or self._root is None or self._quick_window is None):
            return
        self._main_window_shown = True
        window = self._quick_window
        window.frameSwapped.connect(self._hide_splash, Qt.QueuedConnection)

        if IS_WINDOWS:
            shown = QMetaObject.invokeMethod(self._root, "showMainWindow", Qt.QueuedConnection)
        else:
            # Don't wait for a QML timer hosted by the hidden window: it may
            # not advance until the window is exposed, deadlocking start-up.
            window.showMaximized()
            window.raise_()
            window.requestActivate()
            shown = window.isVisible()
        if not shown:
            from camvistra import tslog
            tslog.log_result(0, False, "Unable to show CamVistra main window")
            try:
                window.frameSwapped.disconnect(self._hide_splash)
            except TypeError:
                pass
            self._main_window_shown = False
        else:
            # Some platform/render-loop combinations do not emit frameSwapped
            # promptly; never leave the splash covering the application.
            QTimer.singleShot(1000, self._hide_splash)


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv if argv is None else argv)

    if not IS_WINDOWS:
        # Qt 5's threaded render loop can stall every QQuickFramebufferObject
        # window when Wayland stops presenting an occluded secondary window
        # (the histogram window). Keep an explicit developer override.
        wayland = (os.environ.get("XDG_SESSION_TYPE", "").lower() == "wayland"
                   or bool(os.environ.get("WAYLAND_DISPLAY")))
        if wayland and not os.environ.get("QSG_RENDER_LOOP"):
            os.environ["QSG_RENDER_LOOP"] = "basic"
        # Qt 5 runs under XWayland (xcb + GLX) unless told otherwise, but
        # PyOpenGL picks EGL from XDG_SESSION_TYPE=wayland and then finds no
        # current context. Pin Qt to xcb and make PyOpenGL use the same GL
        # API as Qt's context. Explicit environment settings win.
        if wayland and not os.environ.get("QT_QPA_PLATFORM"):
            os.environ["QT_QPA_PLATFORM"] = "xcb"
        qpa = os.environ.get("QT_QPA_PLATFORM", "xcb").lower()
        egl = (qpa.startswith(("wayland", "eglfs"))
               or os.environ.get("QT_XCB_GL_INTEGRATION", "").lower() == "xcb_egl")
        os.environ.setdefault("PYOPENGL_PLATFORM", "egl" if egl else "glx")

    from camvistra import tslog
    tslog.install_qt_message_handler()  # QML console.log -> log file, not the terminal

    QCoreApplication.setAttribute(Qt.AA_ShareOpenGLContexts)
    QCoreApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
    QCoreApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)
    # The video renderer uses PyOpenGL, which needs a desktop GL context
    # (Qt on Windows may otherwise fall back to ANGLE/GLES).
    QCoreApplication.setAttribute(Qt.AA_UseDesktopOpenGL)

    ub20, ub22, ub24 = _detect_ubuntu()
    if ub22 or ub24 or IS_WINDOWS:
        _init_webengine()
    app = QApplication(argv)

    from camvistra.resources import ensure_resources
    ensure_resources()
    QApplication.setWindowIcon(QIcon(":/View/icons/icon.png"))
    QApplication.setApplicationName(APP_NAME)
    QApplication.setApplicationDisplayName(APP_NAME)  # window title / taskbar text

    splash = SplashController(app)
    splash.start()

    if ub20:
        _init_webengine()
        splash.pump()

    register_qml_types()
    splash.pump()
    # Must run before any camera is opened: summarises NDJSON files left by
    # a session that never finalised (crash or kill).
    from camvistra import feature_flags
    if feature_flags.DIAGNOSTICS_ENABLED:
        from camvistra.diagnostics import scan_for_orphaned_sessions
        scan_for_orphaned_sessions()

    if ub22 or ub24 or IS_WINDOWS:
        qml_main = "qrc:/View/QML/main.qml"
    elif ub20:
        qml_main = "qrc:/View/UB20_QML/main.qml"
    else:
        print("Unsupported OS version detected. Exiting application.", file=sys.stderr)
        splash.close()
        return -1

    backend = CamVistraApp(qml_main, show_window=False, progress=splash.pump)
    if backend.root is None:
        splash.close()
        return -1
    splash.set_root(backend.root)
    try:
        result = app.exec_()
    finally:
        backend.shutdown()
    return result
