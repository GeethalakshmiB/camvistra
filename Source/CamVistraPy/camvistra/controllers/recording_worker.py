"""Background recording start/stop (port of CamVistra/Controller/src/RecordingWorker.cpp).

Media Foundation / FFmpeg recording setup can take 1-2 s, so start/stop run
on a dedicated QThread; results are reported through signals.
"""

from __future__ import annotations

from PyQt5.QtCore import QMetaObject, QObject, Qt, QThread, pyqtSignal, pyqtSlot


class RecordingWorker(QObject):
    """Starts/stops recording on one or more cameras (one file per camera).

    A start succeeds only if every camera starts; otherwise the cameras that
    did start are stopped again so no partial recording is left running.
    """

    recordingStarted = pyqtSignal(bool)
    recordingStopped = pyqtSignal(bool)

    def __init__(self) -> None:
        super().__init__()
        self._jobs: list[tuple[str, object, object]] = []   # (filename, usb_model, net_model)
        self._stop: list[tuple[object, object]] = []         # (usb_model, net_model)

    def start_recording(self, filename: str, usb_model=None, net_model=None) -> None:
        self.start_recordings([(filename, usb_model, net_model)])

    def stop_recording(self, usb_model=None, net_model=None) -> None:
        self.stop_recordings([(usb_model, net_model)])

    def start_recordings(self, jobs: list[tuple[str, object, object]]) -> None:
        self._jobs = list(jobs)
        QMetaObject.invokeMethod(self, "doStartRecording", Qt.QueuedConnection)

    def stop_recordings(self, models: list[tuple[object, object]]) -> None:
        self._stop = list(models)
        QMetaObject.invokeMethod(self, "doStopRecording", Qt.QueuedConnection)

    @staticmethod
    def _model(usb_model, net_model):
        return usb_model if usb_model is not None else net_model

    @pyqtSlot()
    def doStartRecording(self) -> None:
        started = []
        success = bool(self._jobs)
        for filename, usb_model, net_model in self._jobs:
            model = self._model(usb_model, net_model)
            if model is not None and model.start_video_recording(filename) == 1:
                started.append(model)
            else:
                success = False
                break
        if not success:
            for model in started:
                model.stop_recording()
        self.recordingStarted.emit(success)

    @pyqtSlot()
    def doStopRecording(self) -> None:
        success = bool(self._stop)
        for usb_model, net_model in self._stop:
            model = self._model(usb_model, net_model)
            if model is None or model.stop_recording() != 1:
                success = False
        self.recordingStopped.emit(success)


class RecordingThread(QThread):
    """Owns a RecordingWorker living on this thread's event loop."""

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._worker = RecordingWorker()
        self._worker.moveToThread(self)

    def worker(self) -> RecordingWorker:
        return self._worker

    def run(self) -> None:
        self.exec_()

    def shutdown(self) -> None:
        if self.isRunning():
            self.quit()
            self.wait()
