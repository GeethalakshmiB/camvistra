"""Log + tooltip/documentation controller (port of CamVistra/Controller/src/LogController.cpp).

QML context property: ``logController``. Besides the log view it serves the
tooltip and documentation JSON for the Wi-Fi, Routecam and USB settings panes.
"""

from __future__ import annotations

from PyQt5.QtCore import QFile, QIODevice, QObject, QTextStream, pyqtSignal, pyqtSlot

from camvistra.controllers.device_controller import read_qrc_json
from camvistra.device_enums import DeviceEnums
from camvistra.models.log_model import LogModel

WIFI_DOC = ":/View/JSON/wifi_TooltipAndDocumentation.json"
ROUTECAM_DOC = ":/View/JSON/routecam_TooltipAndDocumentation.json"
USB_DOC = ":/View/JSON/usbcam_TooltipAndDocumentation.json"
GRID_DOC = ":/View/JSON/grid_Documentation.json"
CROSSHAIR_DOC = ":/View/JSON/crossHair_Documentation.json"


def _tooltips_only(items: list) -> list:
    """Reduce each object to its "id" and "tooltip" keys (non-objects dropped)."""
    out = []
    for obj in items:
        if not isinstance(obj, dict):
            continue
        out.append({k: obj[k] for k in ("id", "tooltip") if k in obj})
    return out


class LogController(QObject):
    logMessageReceived = pyqtSignal(str, arguments=['logMessage'])
    tooltipAndDocJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    uvcExtTooltipAndDocJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    selectedItem = pyqtSignal(str, arguments=['itemId'])
    selectedExtItem = pyqtSignal(str, arguments=['itemId'])
    htmlFileRead = pyqtSignal(str, arguments=['htmlContent'])
    tooltipJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonTooltipArray'])
    gridDocJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    selectedGridItem = pyqtSignal(str, arguments=['id'])
    crossHairDocJsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    selectedCrossHairItem = pyqtSignal(str, arguments=['id'])

    def __init__(self, log_model: LogModel, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._model = log_model
        log_model.logMessageReceived.connect(self.logMessageReceived)

    # ---- helpers ------------------------------------------------------
    @staticmethod
    def _array(path: str):
        data = read_qrc_json(path)
        return data if isinstance(data, list) else None

    def _emit_full(self, path: str, signal) -> bool:
        data = self._array(path)
        if data is None:
            return False
        signal.emit(data)
        return True

    def _emit_tooltips(self, path: str) -> bool:
        data = self._array(path)
        if data is None:
            return False
        self.tooltipJsonArrayRead.emit(_tooltips_only(data))
        return True

    @staticmethod
    def _usb_ext_doc_path(vid: str, pid: str) -> str | None:
        name = DeviceEnums.json_file_name_from_vid_pid(vid, pid)
        if not name:
            return None
        return f":/View/JSON/{name}_TooltipAndDocumentation.json"

    # ---- log ------------------------------------------------------------
    @pyqtSlot(int, result=int)
    def handleLogPriorityChange(self, currentIndex: int) -> int:
        return self._model.handle_log_priority_change(currentIndex)

    @pyqtSlot(int, str)
    def displayMessage(self, priority: int, message: str) -> None:
        self._model.display_message(priority, message)

    # ---- Wi-Fi camera tooltip & documentation -----------------------------
    @pyqtSlot(result=bool)
    def readJsonArrayFile(self) -> bool:
        return self._emit_full(WIFI_DOC, self.tooltipAndDocJsonArrayRead)

    @pyqtSlot(result=bool)
    def readJsonTooltipArrayFile(self) -> bool:
        return self._emit_tooltips(WIFI_DOC)

    @pyqtSlot(str)
    def expandedItem(self, itemId: str) -> None:
        self.selectedItem.emit(itemId)

    @pyqtSlot(str, result=bool)
    def readHtmlFile(self, filePath: str) -> bool:
        f = QFile(filePath)
        if not f.open(QIODevice.ReadOnly | QIODevice.Text):
            return False
        self.htmlFileRead.emit(QTextStream(f).readAll())
        f.close()
        return True

    # ---- Routecam tooltip & documentation ---------------------------------
    @pyqtSlot(result=bool)
    def readControlJsonTooltipArrayFile(self) -> bool:
        return self._emit_tooltips(ROUTECAM_DOC)

    @pyqtSlot(result=bool)
    def readControlJsonArrayFile(self) -> bool:
        return self._emit_full(ROUTECAM_DOC, self.tooltipAndDocJsonArrayRead)

    # ---- USB camera tooltip & documentation -------------------------------
    @pyqtSlot(str, str, result=bool)
    def readUsbExtControlJsonTooltipArrayFile(self, vid: str, pid: str) -> bool:
        path = self._usb_ext_doc_path(vid, pid)
        return self._emit_tooltips(path) if path else False

    @pyqtSlot(result=bool)
    def readUsbControlJsonTooltipArrayFile(self) -> bool:
        return self._emit_tooltips(USB_DOC)

    @pyqtSlot(result=bool)
    def readUsbControlJsonArrayFile(self) -> bool:
        return self._emit_full(USB_DOC, self.tooltipAndDocJsonArrayRead)

    @pyqtSlot(str, str, result=bool)
    def readUsbExtControlJsonArrayFile(self, vid: str, pid: str) -> bool:
        path = self._usb_ext_doc_path(vid, pid)
        return self._emit_full(path, self.uvcExtTooltipAndDocJsonArrayRead) if path else False

    @pyqtSlot(str)
    def expandedExtItem(self, itemId: str) -> None:
        self.selectedExtItem.emit(itemId)

    # ---- grid / crosshair documentation --------------------------------
    @pyqtSlot(str)
    def expandedGridItem(self, itemId: str) -> None:
        self.selectedGridItem.emit(itemId)

    @pyqtSlot(result=bool)
    def readJsonGridDocArrayFile(self) -> bool:
        return self._emit_full(GRID_DOC, self.gridDocJsonArrayRead)

    @pyqtSlot(str)
    def expandedCrossHairItem(self, itemId: str) -> None:
        self.selectedCrossHairItem.emit(itemId)

    @pyqtSlot(result=bool)
    def readJsonCrossHairDocArrayFile(self) -> bool:
        return self._emit_full(CROSSHAIR_DOC, self.crossHairDocJsonArrayRead)
