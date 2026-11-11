"""Standalone histogram window (port of CamVistra/Histogram/HistogramWindow.{h,cpp})."""

from __future__ import annotations

from PyQt5.QtCore import QEvent, QObject, QSize, QTimer, QUrl, pyqtProperty, pyqtSignal, pyqtSlot
from PyQt5.QtGui import QColor, QSurfaceFormat, QWindow
from PyQt5.QtQuick import QQuickView

from camvistra import tslog
from camvistra.histogram.quick_item import HistogramQuickItem

HISTOGRAM_QML = "qrc:/View/QML/HistogramView.qml"
DEFAULT_SELECTION_COLOR = "#20b7ff"

_PRESENTATION_EVENTS = (QEvent.Expose, QEvent.Show, QEvent.Hide, QEvent.WindowStateChange)


class HistogramWindow(QQuickView):
    closeRequested = pyqtSignal(int)
    selectionModeChanged = pyqtSignal()
    selectionColorChanged = pyqtSignal()
    histogramSelectionModeChanged = pyqtSignal(int, int)
    histogramSelectionColorChanged = pyqtSignal(int, str)
    presentationActiveChanged = pyqtSignal(int, bool)

    def __init__(self, camera_index: int, parent: QWindow | None = None,
                 source: str = HISTOGRAM_QML, camera_name: str = "") -> None:
        super().__init__(parent)
        # QML type + qrc resources must exist before setSource().
        from camvistra.histogram import register_qml_types
        register_qml_types()
        import camvistra.qml_rc  # noqa: F401 - registers qrc:/View/...

        self.camera_index = camera_index
        self._selection_mode = 0
        self._selection_color = QColor(DEFAULT_SELECTION_COLOR)
        self._hist_item: HistogramQuickItem | None = None
        self._last_presentation_active = False

        fmt = QSurfaceFormat()
        fmt.setDepthBufferSize(24)
        fmt.setStencilBufferSize(8)
        fmt.setVersion(2, 0)
        fmt.setProfile(QSurfaceFormat.CompatibilityProfile)
        self.setFormat(fmt)

        # Camera numbers are shown 1-based, matching the preview tiles.
        camera_label = (f"{camera_name} (Camera {camera_index + 1})" if camera_name
                        else f"Camera {camera_index + 1}")
        self.setTitle(f"Histogram — {camera_label}")
        self.setResizeMode(QQuickView.SizeRootObjectToView)
        self.setMinimumSize(QSize(560, 420))
        self.resize(720, 520)
        self.setColor(QColor("#141414"))

        ctx = self.rootContext()
        ctx.setContextProperty("cameraIndex", camera_index)
        ctx.setContextProperty("cameraLabel", camera_label)
        ctx.setContextProperty("histogramWindow", self)

        # Without a handler Qt aborts (qFatal) if no GL context can be created.
        self.sceneGraphError.connect(self._on_scene_graph_error)
        self.statusChanged.connect(self._on_status_changed)
        self.setSource(QUrl(source))
        if self.status() == QQuickView.Ready:
            self._bind_histogram_item()

        # Poll as a fallback for window managers that do not send expose/state
        # events reliably (e.g. on minimise under Wayland).
        self._presentation_timer = QTimer(self)
        self._presentation_timer.setInterval(100)
        self._presentation_timer.timeout.connect(self._refresh_presentation_state)
        self._presentation_timer.start()
        self.installEventFilter(self)

    # ---- QML-facing API --------------------------------------------------------
    @pyqtSlot(QObject)
    def registerHistogramItem(self, item: QObject) -> None:  # noqa: N802
        if isinstance(item, HistogramQuickItem):
            self._hist_item = item

    @pyqtSlot(int)
    def setSelectionMode(self, mode: int) -> None:  # noqa: N802
        mode = max(0, min(3, int(mode)))
        if self._selection_mode == mode:
            return
        self._selection_mode = mode
        self.selectionModeChanged.emit()
        self.histogramSelectionModeChanged.emit(self.camera_index, mode)

    @pyqtProperty(int, fset=setSelectionMode, notify=selectionModeChanged)
    def selectionMode(self) -> int:  # noqa: N802
        return self._selection_mode

    @pyqtSlot(QColor)
    def setSelectionColor(self, color: QColor) -> None:  # noqa: N802
        color = QColor(color)
        if not color.isValid() or color == self._selection_color:
            return
        self._selection_color = color
        self.selectionColorChanged.emit()
        self.histogramSelectionColorChanged.emit(self.camera_index, color.name(QColor.HexRgb))

    @pyqtProperty(QColor, fset=setSelectionColor, notify=selectionColorChanged)
    def selectionColor(self) -> QColor:  # noqa: N802
        return self._selection_color

    def histogram_item(self) -> HistogramQuickItem | None:
        return self._hist_item

    # ---- data -----------------------------------------------------------------
    @pyqtSlot(object)
    def onHistogramReady(self, data) -> None:  # noqa: N802
        if not self.isPresentationActive():
            return
        if self._hist_item is None:
            self._bind_histogram_item()
        if self._hist_item is not None:
            self._hist_item.setHistogramData(data)

    # ---- presentation state ---------------------------------------------------
    def isPresentationActive(self) -> bool:  # noqa: N802
        return (self.isVisible() and self.isExposed()
                and self.visibility() not in (QWindow.Minimized, QWindow.Hidden))

    def _refresh_presentation_state(self) -> None:
        active = self.isPresentationActive()
        if active == self._last_presentation_active:
            return
        self._last_presentation_active = active
        self.presentationActiveChanged.emit(self.camera_index, active)

    def eventFilter(self, watched, event) -> bool:  # noqa: N802
        """HistogramWindow::event(), done as an event filter on the window itself.

        Overriding QQuickView.event() in Python would hold the GIL while
        Qt's expose handling waits for the render thread, and the render
        thread needs the GIL to call our renderer, so that deadlocks. A
        filter runs before the C++ handler, so the refresh that the C++ code
        does after handling is queued with a zero timer instead.
        """
        if watched is self:
            etype = event.type()
            if etype == QEvent.Close:
                self.closeRequested.emit(self.camera_index)
            if etype in _PRESENTATION_EVENTS:
                QTimer.singleShot(0, self._refresh_presentation_state)
        return False

    # ---- internals --------------------------------------------------------------
    def _on_status_changed(self, status) -> None:
        if status == QQuickView.Ready:
            self._bind_histogram_item()
        elif status == QQuickView.Error:
            tslog.log_critical(0, "HistogramWindow QML error: "
                               + "; ".join(e.toString() for e in self.errors()))

    def _on_scene_graph_error(self, _error, message: str) -> None:
        tslog.log_critical(0, f"HistogramWindow scene graph error: {message}")

    def _bind_histogram_item(self) -> None:
        if self._hist_item is not None or self.rootObject() is None:
            return
        root = self.rootObject()
        item = root.findChild(HistogramQuickItem, "histogramItem")
        if item is None:
            items = root.findChildren(HistogramQuickItem)
            item = items[0] if items else None
        if item is None:
            tslog.log_critical(0, "HistogramWindow: HistogramQuickItem not found in QML")
        self._hist_item = item
