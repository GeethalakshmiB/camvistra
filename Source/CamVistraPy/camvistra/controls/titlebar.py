"""Frameless-window drag/resize/maximise handling on Windows.

Port of ``WindowsTitleBarEventFilter`` in CamVistra/main.cpp. The QML root
window is frameless and draws its own title bar; this filter implements
dragging by the title bar, edge resizing and double-click maximise.

"Maximised" is tracked purely through the root window's
``windowsCustomMaximized`` property and ``setGeometry()``; the native
window state is never changed (see the comments below for why).
"""

from __future__ import annotations

from PyQt5.QtCore import QEvent, QObject, QPoint, QRect, QSize, Qt
from PyQt5.QtGui import QWindow

EDGE_MARGIN = 10


def _qround(value: float) -> int:
    """qRound(): round half away from zero (Python's round() is banker's)."""
    return int(value + 0.5) if value >= 0 else int(value - 0.5)


def _to_int(value) -> int:
    """QVariant::toInt(): Qt 5 rounds a double (qRound64) instead of truncating."""
    if value is None:
        return 0
    if isinstance(value, float):
        return _qround(value)
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


class WindowsTitleBarEventFilter(QObject):
    def __init__(self, window: QWindow) -> None:
        super().__init__(window)
        self._window = window
        self._normal_geometry = QRect()
        self._press_geometry = QRect()
        self._press_global = QPoint()
        self._resize_edges = Qt.Edges()
        self._dragging = False
        self._drag_needs_restore = False
        self._drag_ratio = 0.5

    def eventFilter(self, watched: QObject, event: QEvent) -> bool:  # noqa: N802 - Qt API
        win = self._window
        if watched is not win:
            return super().eventFilter(watched, event)

        title_h = _to_int(win.property("titleBarHeight"))
        buttons_w = max(126, title_h * 4)
        etype = event.type()

        if etype == QEvent.MouseButtonPress:
            if event.button() != Qt.LeftButton:
                return super().eventFilter(watched, event)
            local = event.localPos().toPoint()
            maximized = bool(win.property("windowsCustomMaximized"))
            if not maximized:
                if local.x() <= EDGE_MARGIN:
                    self._resize_edges |= Qt.LeftEdge
                if local.x() >= win.width() - EDGE_MARGIN:
                    self._resize_edges |= Qt.RightEdge
                if local.y() <= EDGE_MARGIN:
                    self._resize_edges |= Qt.TopEdge
                if local.y() >= win.height() - EDGE_MARGIN:
                    self._resize_edges |= Qt.BottomEdge
            if self._resize_edges != Qt.Edges():
                self._press_global = event.globalPos()
                self._press_geometry = win.geometry()
                return True
            if local.y() <= title_h and local.x() < win.width() - buttons_w:
                self._dragging = True
                self._drag_needs_restore = maximized
                self._drag_ratio = local.x() / max(1.0, float(win.width()))
                self._press_global = event.globalPos()
                self._press_geometry = win.geometry()
                return True

        if etype == QEvent.MouseMove and (self._resize_edges != Qt.Edges() or self._dragging):
            if not (event.buttons() & Qt.LeftButton):
                self._reset()
                return True
            if self._dragging and self._drag_needs_restore:
                self._ensure_normal_geometry()
                self._press_geometry = QRect(self._normal_geometry)
                self._press_geometry.moveTopLeft(QPoint(
                    _qround(event.globalPos().x() - self._normal_geometry.width() * self._drag_ratio),
                    max(0, event.globalPos().y() - title_h // 2)))
                self._press_global = event.globalPos()
                win.setProperty("windowsCustomMaximized", False)
                self._drag_needs_restore = False

            delta = event.globalPos() - self._press_global
            geo = QRect(self._press_geometry)
            if self._dragging:
                geo.translate(delta)
            else:
                edges = self._resize_edges
                if edges & Qt.LeftEdge:
                    geo.setLeft(geo.left() + delta.x())
                if edges & Qt.RightEdge:
                    geo.setRight(geo.right() + delta.x())
                if edges & Qt.TopEdge:
                    geo.setTop(geo.top() + delta.y())
                if edges & Qt.BottomEdge:
                    geo.setBottom(geo.bottom() + delta.y())
                if geo.width() < win.minimumWidth():
                    if edges & Qt.LeftEdge:
                        geo.setLeft(geo.right() - win.minimumWidth() + 1)
                    else:
                        geo.setRight(geo.left() + win.minimumWidth() - 1)
                if geo.height() < win.minimumHeight():
                    if edges & Qt.TopEdge:
                        geo.setTop(geo.bottom() - win.minimumHeight() + 1)
                    else:
                        geo.setBottom(geo.top() + win.minimumHeight() - 1)
            win.setGeometry(geo)
            return True

        if etype == QEvent.MouseButtonRelease and (self._resize_edges != Qt.Edges() or self._dragging):
            self._reset()
            return True

        if etype != QEvent.MouseButtonDblClick:
            return super().eventFilter(watched, event)

        self._reset()
        if (event.button() != Qt.LeftButton or event.localPos().y() > title_h
                or event.localPos().x() >= win.width() - buttons_w):
            return super().eventFilter(watched, event)

        maximized = bool(win.property("windowsCustomMaximized")) or win.windowState() == Qt.WindowMaximized
        # Deliberately never call setWindowState(): forcing a native state
        # transition makes Windows restore geometry from WINDOWPLACEMENT's
        # rcNormalPosition, which was never populated for this frameless
        # window and defaults to a (-32768, -32768, ...) sentinel.
        if maximized:
            self._ensure_normal_geometry()
            win.setGeometry(self._normal_geometry)
            win.setProperty("windowsCustomMaximized", False)
        else:
            current = win.geometry()
            if current.isValid() and current.x() > -100000 and current.y() > -100000:
                self._normal_geometry = current
            # 1 px smaller than the available rect: Qt's Windows backend
            # silently promotes a frameless window whose geometry exactly
            # matches availableGeometry() to WS_MAXIMIZE (see above).
            available = win.screen().availableGeometry()
            win.setGeometry(available.adjusted(0, 0, -1, -1))
            win.setProperty("windowsCustomMaximized", True)
        win.show()
        win.raise_()
        win.requestActivate()
        return True

    def _ensure_normal_geometry(self) -> None:
        if self._normal_geometry.isValid():
            return
        available = self._window.screen().availableGeometry()
        size = QSize(_qround(available.width() * 0.85), _qround(available.height() * 0.85))
        self._normal_geometry = QRect(
            available.x() + (available.width() - size.width()) // 2,
            available.y() + (available.height() - size.height()) // 2,
            size.width(), size.height())

    def _reset(self) -> None:
        self._resize_edges = Qt.Edges()
        self._dragging = False
        self._drag_needs_restore = False
