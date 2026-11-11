"""Screen/DPI information for responsive QML layouts (port of CamVistra/MonitorHandler.cpp).

QML context property: ``MonitorHandler``. QML reads the properties
(``MonitorHandler.screenResolution.width``); the C++ class additionally
exposed same-named Q_INVOKABLE getters. A QMetaObject cannot hold a property
and a method with the same name in PyQt, and QML only uses the property
form, so only the properties are provided.
"""

from __future__ import annotations

from PyQt5.QtCore import QObject, QSize, pyqtProperty, pyqtSignal, pyqtSlot
from PyQt5.QtGui import QScreen, QWindow


class MonitorHandler(QObject):
    resolutionChanged = pyqtSignal()
    dpiChanged = pyqtSignal()
    screenChanged = pyqtSignal()

    def __init__(self, window: QWindow | None = None, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._window: QWindow | None = None
        self._screen: QScreen | None = None
        if window is not None:
            self.setWindow(window)

    @pyqtSlot(QWindow)
    def setWindow(self, window: QWindow) -> None:
        if window is None:
            return
        self._window = window
        self._screen = window.screen()
        self._connect_screen(self._screen)
        window.screenChanged.connect(self._on_screen_changed)

    def _on_screen_changed(self, new_screen: QScreen) -> None:
        if self._screen is not new_screen:
            self._screen = new_screen
            self._connect_screen(new_screen)
            self.screenChanged.emit()
            self.resolutionChanged.emit()
            self.dpiChanged.emit()

    def _connect_screen(self, screen: QScreen | None) -> None:
        if screen is None:
            return
        screen.geometryChanged.connect(lambda *_: self.resolutionChanged.emit())
        screen.logicalDotsPerInchChanged.connect(lambda *_: self.dpiChanged.emit())

    @pyqtProperty(str, notify=screenChanged)
    def screenName(self) -> str:
        return self._screen.name() if self._screen is not None else ""

    @pyqtProperty(QSize, notify=resolutionChanged)
    def screenResolution(self) -> QSize:
        return self._screen.geometry().size() if self._screen is not None else QSize()

    @pyqtProperty(float, notify=dpiChanged)
    def logicalDpi(self) -> float:
        return self._screen.logicalDotsPerInch() if self._screen is not None else 96.0

    @pyqtSlot()
    def screenInfo(self) -> None:
        self.screenChanged.emit()
        self.resolutionChanged.emit()
        self.dpiChanged.emit()
