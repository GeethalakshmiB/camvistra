"""Recording duration display (port of CamVistra/Controls/DurationTimer.cpp).

Registered as the QML type ``DurationTimer 1.0`` and also exposed as the
context property ``durationTimer``.
"""

from __future__ import annotations

from PyQt5.QtCore import QElapsedTimer, QObject, QTimer, pyqtProperty, pyqtSignal, pyqtSlot


class DurationTimer(QObject):
    durationChanged = pyqtSignal()
    runningChanged = pyqtSignal()
    roundUpChanged = pyqtSignal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._timer = QTimer(self)
        self._timer.setInterval(100)  # 100 ms for smooth response
        self._timer.timeout.connect(self._on_tick)
        self._elapsed = QElapsedTimer()
        self._text = "00:00:00"
        self._last_second = -1
        self._running = False
        self._round_up = True

    @pyqtProperty(str, notify=durationChanged)
    def duration(self) -> str:
        return self._text

    @pyqtProperty(bool, notify=runningChanged)
    def running(self) -> bool:
        return self._running

    def _get_round_up(self) -> bool:
        return self._round_up

    def _set_round_up(self, value: bool) -> None:
        if self._round_up == value:
            return
        self._round_up = value
        self.roundUpChanged.emit()

    roundUp = pyqtProperty(bool, fget=_get_round_up, fset=_set_round_up, notify=roundUpChanged)

    @pyqtSlot()
    def start(self) -> None:
        # A start notification always represents a new recording: restart even
        # if a delayed/missed stop left the timer marked as running.
        was_running = self._running
        self._timer.stop()
        self._elapsed.restart()
        self._last_second = -1
        self._text = "00:00:00"
        self._running = True
        self._timer.start()
        self.durationChanged.emit()
        if not was_running:
            self.runningChanged.emit()

    @pyqtSlot()
    def stop(self) -> None:
        was_running = self._running
        self._timer.stop()
        self._running = False
        self._text = "00:00:00"
        self._last_second = -1
        self.durationChanged.emit()
        if was_running:
            self.runningChanged.emit()

    def _on_tick(self) -> None:
        if not self._running:
            return
        total = self._elapsed.elapsed() // 1000
        if total == self._last_second:
            return
        self._last_second = total
        hours, rem = divmod(total, 3600)
        minutes, seconds = divmod(rem, 60)
        self._text = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        self.durationChanged.emit()
