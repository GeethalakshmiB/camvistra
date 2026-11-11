"""Background histogram computation (port of CamVistra/Histogram/HistogramWorker).

One ``HistogramWorker`` QThread per camera. The processing thread hands
frames over through a native ``sdk.FrameTap``. The tap copies the frame
without the GIL and keeps only the latest one, so the producer never waits
for the worker. ``run()`` takes a frame, computes the histogram and emits
``histogramReady``. Receivers on the GUI thread get it through a queued
connection.
"""

from __future__ import annotations

import threading

from PyQt5.QtCore import QThread, pyqtSignal

from camvistra import tslog
from camvistra.histogram import compute
from camvistra.histogram.data import HistogramSelection
from camvistra.native import sdk


class HistogramWorker(QThread):
    histogramReady = pyqtSignal(object)   # HistogramData (emitted on the worker thread)
    frameSkipped = pyqtSignal(int)        # camera index; frame produced no histogram

    WAIT_TIMEOUT_S = 0.1

    def __init__(self, camera_index: int, parent=None) -> None:
        super().__init__(parent)
        self.camera_index = camera_index
        self.tap = sdk.FrameTap()
        self._selection = HistogramSelection()
        self._sel_lock = threading.Lock()
        self._stopping = False
        self.setObjectName(f"HistogramWorker-{camera_index}")

    # ---- producer side (any thread; never blocks on the computation) ------
    def set_frame_selection(self, selection: HistogramSelection) -> None:
        """Selection that applies to the next frame (C++ passes it with the frame)."""
        with self._sel_lock:
            self._selection = selection.copy()

    def push(self, data, size: int, width: int, height: int, pixfmt: int) -> None:
        """HistogramWorker::pushFrame: copy ``size`` bytes of ``data`` into the tap."""
        if data is None or size <= 0 or width <= 0 or height <= 0:
            return
        mv = memoryview(data)
        if mv.format != "B" or mv.ndim != 1:
            mv = mv.cast("B")
        if size < mv.nbytes:
            mv = mv[:size]
        self.tap.push(mv, width, height, int(pixfmt))

    def push_slot(self, slot) -> None:
        """Copy the current frame of a native ``sdk.FrameSlot`` into the tap."""
        self.tap.push_slot(slot)

    # ---- worker thread -----------------------------------------------------
    def run(self) -> None:  # noqa: D401 - QThread API
        compute.warm_up()
        while not self._stopping:
            item = self.tap.wait(self.WAIT_TIMEOUT_S)
            if item is None:
                continue
            data, width, height, pixfmt = item
            with self._sel_lock:
                selection = self._selection
            try:
                hist = compute.compute_histogram(data, width, height, pixfmt,
                                                 selection, self.camera_index)
            except Exception as exc:  # never let a bad frame kill the thread
                tslog.log_critical(0, f"Histogram computation failed: {exc!r}")
                hist = None
            if hist is None:
                self.frameSkipped.emit(self.camera_index)
            else:
                self.histogramReady.emit(hist)

    def stop(self) -> None:
        """Stop the loop and join the thread (C++: thread->quit(); thread->wait())."""
        self._stopping = True
        self.tap.close()
        self.wait()
