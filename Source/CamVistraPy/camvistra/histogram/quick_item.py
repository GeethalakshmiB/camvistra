"""QML-facing histogram items (port of HistogramQuickItem.{h,cpp} and HistogramDisplay).

``HistogramQuickItem`` is registered as QML type ``HistogramQuickItem`` in
module ``HistogramQuickItem 1.0`` and used by View/QML/HistogramView.qml.
Its property names match the C++ Q_PROPERTYs because QML binds to them.

``HistogramDisplay`` is the legacy item from HistogramDisplay.cpp. The C++
app never registers it with QML (only its test projects compile it). It is
ported for completeness and left unregistered too.
"""

from __future__ import annotations

import threading

import numpy as np
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot
from PyQt5.QtQuick import QQuickFramebufferObject, QQuickItem

from camvistra.histogram.data import BINS, HistogramData
from camvistra.histogram.renderer import HistogramDisplayRenderer, HistogramQuickRenderer


def _average_bin(bins: np.ndarray) -> float:
    count = int(bins.sum(dtype=np.uint64))
    if count == 0:
        return 0.0
    return float(int(np.dot(np.arange(BINS, dtype=np.uint64), bins.astype(np.uint64)))) / count


class HistogramQuickItem(QQuickFramebufferObject):
    channelVisibilityChanged = pyqtSignal()
    statisticsChanged = pyqtSignal()
    themeChanged = pyqtSignal()
    histogramModeChanged = pyqtSignal()
    histogramFormatChanged = pyqtSignal()

    def __init__(self, parent: QQuickItem | None = None) -> None:
        super().__init__(parent)
        self.setMirrorVertically(True)
        self.setFlag(QQuickItem.ItemHasContents, True)
        self._pending = HistogramData()
        self._dirty = False
        self._red = True
        self._green = True
        self._blue = True
        self._alpha = False
        self._light = False
        self._mode = 0
        self._hover = -1
        self._avg = [0.0, 0.0, 0.0, 0.0]
        self._y_max = 0

    def createRenderer(self):  # noqa: N802 - Qt API; render thread
        return HistogramQuickRenderer()

    # ---- data hand-off (GUI thread) / renderer access (sync phase) ----------
    def setHistogramData(self, data: HistogramData) -> None:  # noqa: N802
        was_mono = self._pending.monochrome
        self._pending = data
        visibility_changed = False
        if data.monochrome:
            visibility_changed = self._red or self._green or self._blue or not self._alpha
            self._red = self._green = self._blue = False
            self._alpha = True
        elif was_mono:
            visibility_changed = not self._red or not self._green or not self._blue or self._alpha
            self._red = self._green = self._blue = True
            self._alpha = False
        self._dirty = True
        self._update_statistics()
        self.update()
        if was_mono != data.monochrome:
            self.histogramFormatChanged.emit()
        if visibility_changed:
            self.channelVisibilityChanged.emit()

    def pendingData(self) -> HistogramData:  # noqa: N802
        return self._pending

    def dataDirty(self) -> bool:  # noqa: N802
        return self._dirty

    def clearDirty(self) -> None:  # noqa: N802
        self._dirty = False

    # ---- channel visibility ---------------------------------------------------
    def _set_flag(self, attr: str, value: bool) -> None:
        value = bool(value)
        if getattr(self, attr) == value:
            return
        setattr(self, attr, value)
        self._update_statistics()
        self.update()
        self.channelVisibilityChanged.emit()

    @pyqtProperty(bool, notify=channelVisibilityChanged)
    def showRed(self) -> bool:  # noqa: N802
        return self._red

    @showRed.setter
    def showRed(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_red", v)

    @pyqtProperty(bool, notify=channelVisibilityChanged)
    def showGreen(self) -> bool:  # noqa: N802
        return self._green

    @showGreen.setter
    def showGreen(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_green", v)

    @pyqtProperty(bool, notify=channelVisibilityChanged)
    def showBlue(self) -> bool:  # noqa: N802
        return self._blue

    @showBlue.setter
    def showBlue(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_blue", v)

    @pyqtProperty(bool, notify=channelVisibilityChanged)
    def showAlpha(self) -> bool:  # noqa: N802
        return self._alpha

    @showAlpha.setter
    def showAlpha(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_alpha", v)

    # Explicit setters for Python callers (C++ setShowRed(...) etc.).
    def setShowRed(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_red", v)

    def setShowGreen(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_green", v)

    def setShowBlue(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_blue", v)

    def setShowAlpha(self, v: bool) -> None:  # noqa: N802
        self._set_flag("_alpha", v)

    # ---- theme / mode -------------------------------------------------------
    @pyqtProperty(bool, notify=themeChanged)
    def lightTheme(self) -> bool:  # noqa: N802
        return self._light

    @lightTheme.setter
    def lightTheme(self, v: bool) -> None:  # noqa: N802
        self.setLightTheme(v)

    def setLightTheme(self, v: bool) -> None:  # noqa: N802
        v = bool(v)
        if self._light == v:
            return
        self._light = v
        self.update()
        self.themeChanged.emit()

    @pyqtProperty(int, notify=histogramModeChanged)
    def histogramMode(self) -> int:  # noqa: N802
        return self._mode

    @histogramMode.setter
    def histogramMode(self, mode: int) -> None:  # noqa: N802
        self.setHistogramMode(mode)

    def setHistogramMode(self, mode: int) -> None:  # noqa: N802
        mode = max(0, min(2, int(mode)))
        if self._mode == mode:
            return
        self._mode = mode
        self.update()
        self.histogramModeChanged.emit()

    @pyqtProperty(bool, notify=histogramFormatChanged)
    def monochrome(self) -> bool:
        return bool(self._pending.monochrome)

    # ---- hover / statistics ---------------------------------------------------
    @pyqtSlot(int)
    def setHoverBin(self, bin_: int) -> None:  # noqa: N802
        if self._hover == bin_:
            return
        self._hover = int(bin_)
        self.statisticsChanged.emit()

    @pyqtProperty(int, fset=setHoverBin, notify=statisticsChanged)
    def hoverBin(self) -> int:  # noqa: N802
        return self._hover

    def _bin(self, bins: np.ndarray) -> int:
        return int(bins[self._hover]) if 0 <= self._hover < BINS else 0

    @pyqtProperty(int, notify=statisticsChanged)
    def binRed(self) -> int:  # noqa: N802
        return self._bin(self._pending.red)

    @pyqtProperty(int, notify=statisticsChanged)
    def binGreen(self) -> int:  # noqa: N802
        return self._bin(self._pending.green)

    @pyqtProperty(int, notify=statisticsChanged)
    def binBlue(self) -> int:  # noqa: N802
        return self._bin(self._pending.blue)

    @pyqtProperty(int, notify=statisticsChanged)
    def binAlpha(self) -> int:  # noqa: N802
        return self._bin(self._pending.alpha)

    @pyqtProperty(float, notify=statisticsChanged)
    def averageRed(self) -> float:  # noqa: N802
        return self._avg[0]

    @pyqtProperty(float, notify=statisticsChanged)
    def averageGreen(self) -> float:  # noqa: N802
        return self._avg[1]

    @pyqtProperty(float, notify=statisticsChanged)
    def averageBlue(self) -> float:  # noqa: N802
        return self._avg[2]

    @pyqtProperty(float, notify=statisticsChanged)
    def averageAlpha(self) -> float:  # noqa: N802
        return self._avg[3]

    @pyqtProperty(int, notify=statisticsChanged)
    def yAxisMax(self) -> int:  # noqa: N802
        return self._y_max

    def _update_statistics(self) -> None:
        d = self._pending
        self._avg = [_average_bin(b) for b in (d.red, d.green, d.blue, d.alpha)]
        shown = [b for b, on in ((d.red, self._red), (d.green, self._green),
                                 (d.blue, self._blue), (d.alpha, self._alpha)) if on]
        self._y_max = max((int(b.max()) for b in shown), default=0)
        self.statisticsChanged.emit()


class HistogramDisplay(QQuickFramebufferObject):
    """Legacy histogram item (HistogramDisplay.cpp); fed through updateBins()."""

    cameraIndexChanged = pyqtSignal()

    def __init__(self, parent: QQuickItem | None = None) -> None:
        super().__init__(parent)
        self.setMirrorVertically(True)
        self._camera_index = -1
        self._lock = threading.Lock()
        self._bins: tuple = ([], [], [], [], False)

    def createRenderer(self):  # noqa: N802
        return HistogramDisplayRenderer()

    @pyqtProperty(int, notify=cameraIndexChanged)
    def cameraIndex(self) -> int:  # noqa: N802
        return self._camera_index

    @cameraIndex.setter
    def cameraIndex(self, index: int) -> None:  # noqa: N802
        if self._camera_index == index:
            return
        self._camera_index = int(index)
        self.cameraIndexChanged.emit()

    @pyqtSlot(int, "QVariantList", "QVariantList", "QVariantList", "QVariantList", bool)
    def updateBins(self, camera_index, luminance, red, green, blue, has_rgb) -> None:  # noqa: N802
        if self._camera_index != camera_index:
            return
        conv = [np.asarray([float(v) for v in lst], dtype=np.float32)
                for lst in (luminance, red, green, blue)]
        with self._lock:
            self._bins = (*conv, bool(has_rgb))
        self.update()

    def copyBins(self) -> tuple:  # noqa: N802
        with self._lock:
            return self._bins
