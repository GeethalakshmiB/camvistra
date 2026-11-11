"""Histogram window and worker coordinator (port of CamVistra/Histogram/HistogramManager).

Threading contract:

* ``create_*`` / ``destroy_*`` / ``set_*`` may be called from any thread.
  Window work always runs on the manager's (GUI) thread: creation from
  another thread is a blocking queued call, destruction a queued call,
  both as in the C++ code.
* ``push_frame`` / ``push_frame_from_slot`` run on the camera processing
  thread once per frame. With no window for the index they return after
  one dict lookup. Otherwise they take a short lock for the rate-limit
  checks and hand the frame to the worker's ``FrameTap``. The tap copies
  without the GIL and never waits for the worker.
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass
from typing import Callable

from PyQt5.QtCore import (Q_ARG, QCoreApplication, QMetaObject, QObject, Qt, QThread, QTimer,
                          pyqtSignal, pyqtSlot)
from PyQt5.QtGui import QColor
from PyQt5 import sip

from camvistra import tslog
from camvistra.histogram.data import HistogramSelection
from camvistra.histogram.worker import HistogramWorker

HISTOGRAM_UPDATE_INTERVAL_S = 0.200   # C++ HistogramUpdateIntervalMs
PENDING_TIMEOUT_S = 0.750             # C++ 750 ms pendingFrames fallback timer


def clamp_selection_mode(mode: int) -> int:
    return max(0, min(3, int(mode)))


@dataclass
class _Entry:
    window: object
    worker: HistogramWorker
    presentation_active: bool = False


class HistogramManager(QObject):
    histogramSelectionModeChanged = pyqtSignal(int, int)
    histogramSelectionColorChanged = pyqtSignal(int, str)
    histogramWindowVisibilityChanged = pyqtSignal(bool)

    def __init__(self, parent: QObject | None = None,
                 window_factory: Callable[[int], object] | None = None) -> None:
        super().__init__(parent)
        self._window_factory = window_factory
        self._entries: dict[int, _Entry] = {}   # written on the GUI thread only
        self._pending_creates: set[int] = set()
        self._active: set[int] = set()
        self._pending: dict[int, float] = {}    # index -> monotonic time of hand-off
        self._last_push: dict[int, float] = {}
        self._selections: dict[int, HistogramSelection] = {}
        self._lock = threading.Lock()
        app = QCoreApplication.instance()
        if app is not None:
            app.aboutToQuit.connect(self.destroy_all)

    # ---- helpers ------------------------------------------------------------
    def _on_gui_thread(self) -> bool:
        return QThread.currentThread() is self.thread()

    def _make_window(self, index: int, name: str = ""):
        if self._window_factory is not None:
            return self._window_factory(index)
        from camvistra.histogram.window import HistogramWindow
        return HistogramWindow(index, camera_name=name)

    # ---- creation -------------------------------------------------------------
    def create_histogram_window(self, index: int, name: str = "") -> None:
        if not self._on_gui_thread():
            QMetaObject.invokeMethod(self, "_create_impl", Qt.BlockingQueuedConnection,
                                     Q_ARG(int, index), Q_ARG(str, name))
            return
        self._create_impl(index, name)

    def create_histogram_window_delayed(self, index: int, delay_ms: int, name: str = "") -> None:
        if not self._on_gui_thread():
            QMetaObject.invokeMethod(self, "_create_delayed_impl", Qt.QueuedConnection,
                                     Q_ARG(int, index), Q_ARG(int, delay_ms), Q_ARG(str, name))
            return
        self._create_delayed_impl(index, delay_ms, name)

    @pyqtSlot(int, int, str)
    def _create_delayed_impl(self, index: int, delay_ms: int, name: str = "") -> None:
        self._pending_creates.add(index)

        def fire() -> None:
            if index in self._pending_creates:
                self._pending_creates.discard(index)
                self._create_impl(index, name)

        QTimer.singleShot(int(delay_ms), fire)

    @pyqtSlot(int, str)
    def _create_impl(self, index: int, name: str = "") -> None:
        if index in self._entries:
            return
        window = self._make_window(index, name)
        window.setFlags(Qt.Window)
        window.closeRequested.connect(self._destroy_impl, Qt.QueuedConnection)
        window.histogramSelectionModeChanged.connect(self.set_histogram_selection_mode,
                                                     Qt.QueuedConnection)
        window.histogramSelectionColorChanged.connect(self.histogramSelectionColorChanged,
                                                      Qt.QueuedConnection)
        window.presentationActiveChanged.connect(self._on_presentation_active_changed)
        window.show()

        worker = HistogramWorker(index)
        worker.histogramReady.connect(window.onHistogramReady, Qt.QueuedConnection)
        worker.histogramReady.connect(self._on_histogram_ready, Qt.QueuedConnection)
        entry = _Entry(window, worker, bool(window.isPresentationActive()))
        worker.start()
        with self._lock:
            self._entries[index] = entry
            self._active.add(index)
            self._last_push.pop(index, None)
            self._pending.pop(index, None)
            self._selections[index] = HistogramSelection()
        self.histogramSelectionModeChanged.emit(index, 0)
        self.histogramSelectionColorChanged.emit(index, QColor(window.selectionColor).name(QColor.HexRgb))
        self.histogramWindowVisibilityChanged.emit(True)
        tslog.log_info(1, f"Histogram window created for camera {index}")

    # ---- destruction ------------------------------------------------------------
    def destroy_histogram_window(self, index: int) -> None:
        if not self._on_gui_thread():
            QMetaObject.invokeMethod(self, "_destroy_impl", Qt.QueuedConnection, Q_ARG(int, index))
            return
        self._destroy_impl(index)

    @pyqtSlot(int)
    def _destroy_impl(self, index: int) -> None:
        self._pending_creates.discard(index)
        with self._lock:
            self._active.discard(index)
            self._pending.pop(index, None)
            self._last_push.pop(index, None)
            self._selections.pop(index, None)
            has_active = bool(self._active)
            entry = self._entries.pop(index, None)
        self.histogramSelectionModeChanged.emit(index, 0)
        self.histogramWindowVisibilityChanged.emit(has_active)
        if entry is None:
            return
        entry.worker.stop()
        try:
            entry.worker.histogramReady.disconnect()
        except TypeError:
            pass
        window = entry.window
        for sig in ("closeRequested", "histogramSelectionModeChanged",
                    "histogramSelectionColorChanged", "presentationActiveChanged"):
            try:
                getattr(window, sig).disconnect()
            except TypeError:
                pass
        window.close()
        if isinstance(window, QObject) and not sip.isdeleted(window):
            sip.transferto(window, None)  # let deleteLater, not Python GC, delete it
            window.deleteLater()
        tslog.log_info(1, f"Histogram window destroyed for camera {index}")

    @pyqtSlot()
    def destroy_all(self) -> None:
        if not self._on_gui_thread():
            QMetaObject.invokeMethod(self, "destroy_all", Qt.QueuedConnection)
            return
        for index in list(self._entries):
            self._destroy_impl(index)

    def has_histogram_window(self, index: int) -> bool:
        with self._lock:
            return index in self._active

    # ---- selection -----------------------------------------------------------------
    def set_histogram_selection(self, index: int, selection: HistogramSelection) -> None:
        with self._lock:
            if index not in self._active:
                return
            sel = selection.copy()
            sel.mode = clamp_selection_mode(sel.mode)
            self._selections[index] = sel

    @pyqtSlot(int, int)
    def set_histogram_selection_mode(self, index: int, mode: int) -> None:
        mode = clamp_selection_mode(mode)
        with self._lock:
            sel = self._selections.get(index, HistogramSelection()).copy()
            sel.mode = mode
            self._selections[index] = sel
        self.histogramSelectionModeChanged.emit(index, mode)

    def histogram_selection(self, index: int) -> HistogramSelection | None:
        with self._lock:
            sel = self._selections.get(index)
            return sel.copy() if sel is not None else None

    # ---- frames (processing thread) -------------------------------------------------
    def _admit(self, index: int) -> HistogramWorker | None:
        """Rate limiting of HistogramManager::pushFrame. Returns the worker to feed."""
        now = time.monotonic()
        with self._lock:
            if index not in self._active:
                return None
            last = self._last_push.get(index)
            if last is not None and now - last < HISTOGRAM_UPDATE_INTERVAL_S:
                return None
            entry = self._entries.get(index)
            if entry is None or not entry.presentation_active:
                return None
            pending = self._pending.get(index)
            if pending is not None and now - pending < PENDING_TIMEOUT_S:
                return None
            self._last_push[index] = now
            self._pending[index] = now
            entry.worker.set_frame_selection(self._selections.get(index, HistogramSelection()))
            return entry.worker

    def push_frame(self, index: int, data, size: int, width: int, height: int, pixfmt: int) -> None:
        if index not in self._entries:   # fast path: no window for this camera
            return
        worker = self._admit(index)
        if worker is not None:
            worker.push(data, size, width, height, pixfmt)

    def push_frame_from_slot(self, index: int, slot) -> None:
        if index not in self._entries:
            return
        worker = self._admit(index)
        if worker is not None:
            worker.push_slot(slot)

    # ---- GUI-thread callbacks ----------------------------------------------------------
    @pyqtSlot(object)
    def _on_histogram_ready(self, hist) -> None:
        with self._lock:
            self._pending.pop(hist.camera_index, None)

    @pyqtSlot(int, bool)
    def _on_presentation_active_changed(self, index: int, active: bool) -> None:
        with self._lock:
            entry = self._entries.get(index)
            if entry is None:
                return
            entry.presentation_active = active
            if not active:
                self._pending.pop(index, None)

    def window(self, index: int):
        """The HistogramWindow of ``index`` (or None)."""
        entry = self._entries.get(index)
        return entry.window if entry is not None else None
