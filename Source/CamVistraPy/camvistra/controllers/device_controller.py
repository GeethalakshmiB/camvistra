"""Device discovery controller (port of CamVistra/Controller/src/DeviceController.cpp).

QML context property: ``devController``.
"""

from __future__ import annotations

import threading

from PyQt5.QtCore import QFile, QIODevice, QJsonDocument, QObject, pyqtSignal, pyqtSlot, qDebug

from camvistra import tslog
from camvistra.models.device_model import DeviceModel

# C++ initController(): "Scan every 3 seconds" (3000 ms in 100 ms steps).
SCAN_INTERVAL_S = 3.0


def read_qrc_json(path: str):
    """Parse a JSON file (Qt resource or disk) exactly like the C++ code: with
    QJsonDocument, whose leniency differs from Python's json module (e.g. raw
    control characters inside strings). Returns None if unreadable/invalid."""
    f = QFile(path)
    if not f.open(QIODevice.ReadOnly):
        return None
    try:
        doc = QJsonDocument.fromJson(f.readAll())
    finally:
        f.close()
    if doc.isNull():
        return None
    return doc.toVariant()


class DeviceController(QObject):
    uiControllerInitialized = pyqtSignal()
    deviceJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    devicesUpdated = pyqtSignal(int, int, arguments=['index', 'devStat'])
    deviceAdded = pyqtSignal("QVariantMap", arguments=['device'])
    deviceStatus = pyqtSignal(str, arguments=['status'])
    deviceRemoved = pyqtSignal("QVariantList", arguments=['currentDeviceList'])

    def __init__(self, device_model: DeviceModel, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._model = device_model
        self._lock = threading.Lock()
        self._scanning = threading.Event()
        self._thread: threading.Thread | None = None

    # ------------------------------------------------------------------
    @pyqtSlot(result=int)
    def uiComponentLoaded(self) -> int:
        """Entry point once the QML view has loaded: starts device scanning."""
        result = self.init_controller()
        return tslog.log_result(result, result == 1)

    def init_controller(self) -> int:
        if self._scanning.is_set():
            return 1
        self._model.deviceAdded.connect(self.deviceAdded)
        self._model.deviceRemoved.connect(self.deviceRemoved)
        self._model.deviceStatus.connect(self.deviceStatus)

        self._scanning.set()
        # DeviceManager.enumerateAllDevices() may block while probing USB and
        # network interfaces, so it runs on a worker thread (GIL released in
        # the binding). Signals emitted there are queued to the GUI thread.
        self._thread = threading.Thread(target=self._scan_loop, name="DeviceScan", daemon=True)
        self._thread.start()
        self.uiControllerInitialized.emit()
        return 1

    def _scan_loop(self) -> None:
        while self._scanning.is_set():
            with self._lock:
                self._model.get_devices()
            # wait() doubles as an interruptible sleep for shutdown()
            if self._wait_stop(SCAN_INTERVAL_S):
                break

    def _wait_stop(self, timeout: float) -> bool:
        stop = getattr(self, "_stop_event", None)
        if stop is None:
            self._stop_event = stop = threading.Event()
        return stop.wait(timeout)

    def shutdown(self) -> None:
        """Stop the scan thread (C++: ~DeviceController joins it)."""
        self._scanning.clear()
        if getattr(self, "_stop_event", None) is not None:
            self._stop_event.set()
        if self._thread is not None:
            self._thread.join(timeout=10)
            self._thread = None

    # ------------------------------------------------------------------
    @pyqtSlot(result=bool)
    def readJsonArrayFile(self) -> bool:
        f = QFile(":/View/JSON/devices.json")
        if not f.open(QIODevice.ReadOnly):
            qDebug("Failed to open the file: " + f.errorString())
            return tslog.log_bool_result(False, "Unable to open devices.json")
        data = f.readAll()
        f.close()
        doc = QJsonDocument.fromJson(data)
        if doc.isNull():
            qDebug("Failed to parse JSON.")
            return tslog.log_bool_result(False, "Invalid devices.json")
        if not doc.isArray():
            return tslog.log_bool_result(False, "JSON root is not an array")
        self.deviceJsonArrayRead.emit(doc.toVariant())
        return tslog.log_bool_result(True)

    @pyqtSlot(result=int)
    def getDevices(self) -> int:
        with self._lock:
            result = self._model.get_devices()
        if result != 1:
            tslog.log_critical(result)
        return result

    @pyqtSlot(str, result=bool)
    def addDeviceToTheList(self, ipAddress: str) -> bool:
        with self._lock:
            return tslog.log_bool_result(self._model.add_device_to_the_list(ipAddress))

    @pyqtSlot(result=bool)
    def removeManuallyAddedDevice(self) -> bool:
        with self._lock:
            return tslog.log_bool_result(self._model.remove_manually_added_device())

    @pyqtSlot(str, result=bool)
    def addWifiDeviceToTheList(self, ipAddress: str) -> bool:
        with self._lock:
            return tslog.log_bool_result(self._model.add_wifi_device_to_the_list(ipAddress))
