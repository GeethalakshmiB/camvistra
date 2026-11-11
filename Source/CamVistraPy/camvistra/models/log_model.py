"""Log view model (port of CamVistra/Model/src/LogModel.cpp).

Receives every SDK/application log record through the Logger callback and
forwards those matching the priority selected in the UI.
"""

from __future__ import annotations

from datetime import datetime

from PyQt5.QtCore import QObject, pyqtSignal

from camvistra import tslog
from camvistra.native import Result, sdk


class LogModel(QObject):
    logMessageReceived = pyqtSignal(str)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.log_priority = 0
        self._logger = sdk.Logger()
        # Called from any SDK thread; the signal is queued to the GUI thread.
        res = self._logger.setLogCallback(self.display_message)
        tslog.log_result(res, res == Result.Ok, "Logger callback registration")

    def display_message(self, log_prior: int, log_message: str) -> None:
        if self.log_priority == log_prior:
            timestamp = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
            self.logMessageReceived.emit(f"{timestamp} : {log_message}")

    def handle_log_priority_change(self, current_index: int) -> int:
        self.log_priority = current_index
        return 1

    def close(self) -> None:
        self._logger.clearLogCallback()
