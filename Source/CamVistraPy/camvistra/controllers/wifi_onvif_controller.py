"""ShelfVista (Wi-Fi) ONVIF controller.

Port of CamVistra/Controller/include/WifiOnvifController.h and
CamVistra/Controller/src/WifiOnvifController.cpp.
QML context property: ``wifiOnvifController``.

Threading: identical to the C++ build - every Q_INVOKABLE runs synchronously
on the calling (GUI) thread and calls the SDK through
:class:`~camvistra.models.wifi_onvif_model.WifiOnvifModel` directly (the C++
controller has no worker thread for this camera family).

Diagnostics: the C++ controller has every diagnostics call commented out
(session start/end and control-change reports), so this port makes none
either. The helpers below are kept for when the C++ re-enables them.
"""

from __future__ import annotations

import base64
import importlib
import logging
import os
import re
import sys

from PyQt5.QtCore import (QCoreApplication, QDateTime, QDir, QFile, QIODevice, QJsonDocument,
                          QJsonValue, QObject, QStandardPaths, pyqtSignal, pyqtSlot)

from camvistra.models.wifi_onvif_model import (CHAR_SIZES, RANGE, SERVER_DATA, CameraConfigProperty,
                                               WifiOnvifModel, c_div, c_str, merge_struct, qstr_to_int,
                                               qv_to_bool, qv_to_int, qv_to_list, qv_to_map, qv_to_str)

_log = logging.getLogger(__name__)

P = CameraConfigProperty

_DURATION_RE = re.compile(r"(\d+)\s*(sec|secs|second|seconds|min|mins|minute|minutes)")


# ---------------------------------------------------------------------------
# Diagnostics glue (shared with the Routecam controller)
# ---------------------------------------------------------------------------

def diagnostics_manager():
    """``DiagnosticsManager.instance()`` or None when the module is missing."""
    try:
        from camvistra.diagnostics import DiagnosticsManager
    except ImportError:
        _log.debug("camvistra.diagnostics not available - diagnostics disabled")
        return None
    return DiagnosticsManager.instance()


def make_diagnostics_adapter(class_name: str):
    """Instantiate ``camvistra.diagnostics.<class_name>()`` (None if missing)."""
    try:
        cls = getattr(importlib.import_module("camvistra.diagnostics"), class_name)
    except (ImportError, AttributeError):
        _log.debug("camvistra.diagnostics.%s not available", class_name)
        return None
    return cls()


def adapter_report(adapter, method: str, *args) -> None:
    """Call ``adapter.<method>`` (snake_case preferred, C++ camelCase accepted)."""
    if adapter is None:
        return
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", method).lower()
    fn = getattr(adapter, snake, None) or getattr(adapter, method, None)
    if fn is not None:
        fn(*args)


def restart_diagnostics_session(key: str, camera_name: str, adapter) -> None:
    """C++: end any open session for ``key`` then start a fresh one (no FPS)."""
    mgr = diagnostics_manager()
    if mgr is None:
        return
    # Reopen always starts a new session/report, never appends to a previous one.
    if mgr.has_session(key):
        mgr.end_session(key)
    # No FPS getter exists on the model's public API, so this family's
    # sessions capture CPU/memory and control-change charts only.
    mgr.start_session(key, camera_name, nominal_fps=0.0, fps_provider=None,
                      control_provider=adapter)


def end_diagnostics_session(key: str) -> None:
    mgr = diagnostics_manager()
    if mgr is not None and mgr.has_session(key):
        mgr.end_session(key)


def read_json_document(path: str) -> tuple[bool, QJsonDocument | None, str]:
    """Open + parse ``path`` with QFile/QJsonDocument: (opened, doc, errorString)."""
    f = QFile(path)
    if not f.open(QIODevice.ReadOnly):
        return False, None, f.errorString()
    data = f.readAll()
    f.close()
    return True, QJsonDocument.fromJson(data), ""


def desktop_location() -> str:
    """Folder that snapshotWorker saves into (the C++ uses the desktop)."""
    return QStandardPaths.writableLocation(QStandardPaths.DesktopLocation)


def downloads_location() -> tuple[str, str]:
    """(downloadsPath, sudoUser) as computed by the C++ download helpers."""
    sudo_user = ""
    if sys.platform.startswith("linux"):
        sudo_user = os.environ.get("SUDO_USER", "")
        if sudo_user:
            # Running via sudo -> real user's Downloads
            return "/home/" + sudo_user + "/Downloads", sudo_user
    return QStandardPaths.writableLocation(QStandardPaths.DownloadLocation), sudo_user


class WifiOnvifController(QObject):
    onvifInitialized = pyqtSignal()
    jsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    saJsonFileContent = pyqtSignal("QVariantMap", arguments=['jsonArray'])
    azureJsonFileRead = pyqtSignal(str, str, arguments=['fileName', 'sharedKey'])
    statusChanged = pyqtSignal(str, arguments=['status'])
    jsonFileReadFailed = pyqtSignal(str, arguments=['msg'])
    currentResolutionReceived = pyqtSignal(str, arguments=['currentResolution'])
    availableResolutionsList = pyqtSignal("QVariantList", arguments=['list'])
    firmwareVersion = pyqtSignal(str, arguments=['firmwareVersion'])
    defaultResolution = pyqtSignal(str, arguments=['resolution'])
    sdCardEjected = pyqtSignal()
    defaultUiValues = pyqtSignal("QVariantMap", arguments=['values'])
    sdCardInfo = pyqtSignal(str, arguments=['message'])
    # Diagnostics: one WifiOnvif connection at a time, keyed by a fixed string.
    kDiagnosticsSessionKey = "WifiOnvif"

    def __init__(self, model: WifiOnvifModel | None = None, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.wifiOnvifModel = model if model is not None else WifiOnvifModel()
        m = self.wifiOnvifModel
        m.statusChanged.connect(self.statusChanged)
        m.onvifInitialized.connect(self.onvifInitialized)
        m.currentResolutionReceived.connect(self.currentResolutionReceived)
        m.availableResolutionsList.connect(self.availableResolutionsList)
        m.defaultResolution.connect(self.defaultResolution)
        m.sdCardEjected.connect(self.sdCardEjected)
        m.defaultUiValues.connect(self.defaultUiValues)
        m.sdCardInfo.connect(self.sdCardInfo)

        self.isHmacAndSaAvailable = False
        self.isAzureConfigAvailable = False
        self.isSASTokenAvailable = False
        self.isOEM = False

        self._diagnosticsControlAdapter = None
        self._diagnosticsAdapterCreated = False
        self._shutdown_done = False
        app = QCoreApplication.instance()
        if app is not None:
            app.aboutToQuit.connect(self.shutdown)

    # ------------------------------------------------------------------
    # Lifecycle (C++: ~WifiOnvifController)
    # ------------------------------------------------------------------

    def shutdown(self) -> None:
        """C++ ~WifiOnvifController: its diagnostics endSession() is commented out."""
        if self._shutdown_done:
            return
        self._shutdown_done = True
        # end_diagnostics_session(self.kDiagnosticsSessionKey)

    @property
    def diagnosticsControlAdapter(self):
        if not self._diagnosticsAdapterCreated:
            self._diagnosticsAdapterCreated = True
            self._diagnosticsControlAdapter = make_diagnostics_adapter("WifiOnvifControlAdapter")
        return self._diagnosticsControlAdapter

    # ------------------------------------------------------------------
    @pyqtSlot(result=bool)
    def readJsonArrayFile(self) -> bool:
        opened, doc, err = read_json_document(":/View/JSON/wifiProperty.json")
        if not opened:
            _log.debug("Failed to open the file: %s", err)
            return False
        if doc.isNull():
            _log.debug("Failed to parse JSON.")
            return False
        if doc.isArray():
            self.jsonArrayRead.emit(doc.toVariant())
        else:
            _log.debug("The JSON is not an array.")
            return False
        return True

    @pyqtSlot(str, result=int)
    def initializeOnvif(self, ipAddress: str) -> int:
        result = self.wifiOnvifModel.initializeOnvif(ipAddress)
        # Diagnostics session restart is commented out in C++:
        # if result == 1:
        #     restart_diagnostics_session(self.kDiagnosticsSessionKey, ipAddress,
        #                                 self.diagnosticsControlAdapter)
        return result

    @pyqtSlot(result="QVariantMap")
    def getDeviceInformationMap(self) -> dict:
        infoMap: dict = {}
        result, info = self.wifiOnvifModel.getDeviceInformation()
        if result == 1:
            infoMap["manufacturer"] = info["manufacturer"]
            infoMap["model"] = info["model"]
            infoMap["firmwareVersion"] = info["firmwareVersion"]
            self.firmwareVersion.emit("Firmware version:  " + info["firmwareVersion"])
            infoMap["serialNumber"] = info["serialNumber"]
            infoMap["hardwareId"] = info["hardwareId"]
        else:
            _log.debug("Error: Failed to retrieve device information.")
        return infoMap

    @pyqtSlot(result="QVariantMap")
    def getBatteryStatusMap(self) -> dict:
        infoMap: dict = {}
        result, info = self.wifiOnvifModel.getBatteryStatus()
        if result == 1:
            infoMap["batteryStatus"] = info["batteryStatus"]
            infoMap["chargingStatus"] = info["chargingStatus"]
        else:
            _log.debug("Error: Failed to retrieve device information.")
        return infoMap

    @pyqtSlot(result="QVariantMap")
    def getCapabilitiesMap(self) -> dict:
        capMap: dict = {}
        result, caps = self.wifiOnvifModel.getCapabilities()
        if result == 1:
            for key in ("HMAC", "ServiceAccount", "Azure", "SASToken", "OEM",
                        "Brightness", "Contrast", "ExposureMode", "Sharpness", "Saturation"):
                capMap[key] = bool(caps[key])
            capMap["wbMode"] = bool(caps["WhiteBalanceMode"])
            for key in ("FPS", "Pan", "Tilt", "Zoom", "BatteryStatus", "Trigger"):
                capMap[key] = bool(caps[key])

            # Reflect the current device only; flags from a previously
            # connected camera must not carry over.
            self.isOEM = bool(caps["OEM"])
            self.isAzureConfigAvailable = bool(caps["Azure"])
            self.isSASTokenAvailable = bool(caps["Azure"] and caps["SASToken"])
            self.isHmacAndSaAvailable = bool(not caps["Azure"] and caps["ServiceAccount"] and caps["HMAC"])
        else:
            self.isOEM = False
            self.isAzureConfigAvailable = False
            self.isSASTokenAvailable = False
            self.isHmacAndSaAvailable = False
            _log.debug("Error: Failed to retrieve device information.")
        return capMap

    @pyqtSlot("QVariantMap", result=bool)
    def setCameraConfigMap(self, camConfigMap: dict) -> bool:
        camConfData = {"qFactor": 0, "antibanding": 0}
        antibanding = qv_to_str(camConfigMap.get("antibanding"))
        if antibanding == "50Hz":
            camConfData["antibanding"] = 1
        elif antibanding == "60Hz":
            camConfData["antibanding"] = 0
        camConfData["qFactor"] = qv_to_int(camConfigMap.get("qFactor"))
        if self.wifiOnvifModel.setCameraConfigSettings(camConfData) == 1:
            return True
        _log.debug("Error: Failed to set Server configuration.")
        return False

    @pyqtSlot(result=int)
    def reboot(self) -> int:
        return self.wifiOnvifModel.reboot()

    @pyqtSlot(result="QVariantMap")
    def getAPConfigMap(self) -> dict:
        apConfigMap: dict = {}
        result, ap = self.wifiOnvifModel.getAPConfig()
        if result == 1:
            apConfigMap["SSID"] = ap["SSID"]
            apConfigMap["password"] = ap["password"]
            apConfigMap["securityMode"] = ap["securityMode"]
            apConfigMap["band"] = int(ap["band"])
            apConfigMap["channel"] = int(ap["channel"])
        else:
            _log.debug("Error: Failed to retrieve AP configuration.")
        return apConfigMap

    @pyqtSlot(result="QVariantMap")
    def getSTAConfigMap(self) -> dict:
        staConfigMap: dict = {}
        result, sta = self.wifiOnvifModel.getSTAConfig()
        if result == 1:
            for key in ("SSID", "password", "ipConfig", "ipAddress", "subnetMask", "gateway",
                        "primaryDNS"):
                staConfigMap[key] = sta[key]
        else:
            _log.debug("Error: Failed to retrieve STA configuration.")
        return staConfigMap

    def _cloud_branch(self, provider: str) -> str:
        """Which cloud-config layout applies ("hmac_sa", "azure" or "legacy")."""
        if self.isHmacAndSaAvailable or (self.isAzureConfigAvailable
                                         and provider in ("Amazon", "Google")):
            return "hmac_sa"
        if self.isAzureConfigAvailable:
            return "azure"
        return "legacy"

    @pyqtSlot(result="QVariantMap")
    def getServerConfigMap(self) -> dict:
        serverConfigMap: dict = {}
        result, data = self.wifiOnvifModel.getServerConfig()
        if result == 1:
            serverConfigMap["mode"] = bool(data["mode"])  # false = Local, true = Cloud
            local, cloud = data["localConfig"], data["cloudConfig"]

            localConfig = {"IP": local["IP"], "Port": int(local["Port"])}

            cloudConfig = {"Provider": cloud["Provider"]}
            branch = self._cloud_branch(cloud["Provider"])
            if branch == "hmac_sa":
                cloudConfig["AccountType"] = cloud["AccountType"]
                if cloudConfig["AccountType"] == "HMAC":
                    for key in ("AccessKey", "SecretKey", "Region", "BucketNameHMAC"):
                        cloudConfig[key] = cloud[key]
                elif cloudConfig["AccountType"] == "SA":
                    cloudConfig["ServiceAccountJsonFileName"] = cloud["ServiceAccountJsonFileName"]
                    cloudConfig["BucketNameSA"] = cloud["BucketNameSA"]
            elif branch == "azure":
                for key in ("AccountType", "AzureContainerName", "AzureAccountName",
                            "AzureAccountKey"):
                    cloudConfig[key] = cloud[key]
            else:
                for key in ("AccessKey", "SecretKey", "Region", "BucketName"):
                    cloudConfig[key] = cloud[key]

            serverConfigMap["localConfig"] = localConfig
            serverConfigMap["cloudConfig"] = cloudConfig
        else:
            _log.debug("Error: Failed to retrieve Server configuration.")
        return serverConfigMap

    @pyqtSlot("QVariantMap", result=bool)
    def setAPConfigMap(self, apConfigMap: dict) -> bool:
        sizes = CHAR_SIZES["AP"]
        apData = {
            "SSID": c_str(qv_to_str(apConfigMap.get("SSID")), sizes["SSID"]),
            "password": c_str(qv_to_str(apConfigMap.get("password")), sizes["password"]),
            "securityMode": c_str(qv_to_str(apConfigMap.get("securityMode")), sizes["securityMode"]),
            "band": qv_to_int(apConfigMap.get("band")),
            "channel": qv_to_int(apConfigMap.get("channel")),
        }
        return self.wifiOnvifModel.setAPConfig(apData) == 1

    @pyqtSlot("QVariantMap", result=bool)
    def setSTAConfigMap(self, staConfigMap: dict) -> bool:
        staData = {key: c_str(qv_to_str(staConfigMap.get(key)), size)
                   for key, size in CHAR_SIZES["STA"].items()}
        return self.wifiOnvifModel.setSTAConfig(staData) == 1

    @pyqtSlot("QVariantMap", result=bool)
    def setServerConfigMap(self, serverConfigMap: dict) -> bool:
        serverData = merge_struct(SERVER_DATA, None)
        sizes = CHAR_SIZES["CLOUD"]

        serverData["mode"] = qv_to_bool(serverConfigMap.get("mode"))  # false = Local, true = Cloud

        localConfig = qv_to_map(serverConfigMap.get("localConfig"))
        serverData["localConfig"]["IP"] = c_str(qv_to_str(localConfig.get("IP")),
                                                CHAR_SIZES["LOCAL"]["IP"])
        serverData["localConfig"]["Port"] = qv_to_int(localConfig.get("Port"))

        cloudConfig = qv_to_map(serverConfigMap.get("cloudConfig"))
        cloud = serverData["cloudConfig"]

        def copy(key: str) -> None:
            cloud[key] = c_str(qv_to_str(cloudConfig.get(key)), sizes[key])

        copy("Provider")
        branch = self._cloud_branch(cloud["Provider"])
        if branch == "hmac_sa":
            copy("AccountType")
            if cloud["AccountType"] == "HMAC":
                for key in ("AccessKey", "SecretKey", "Region", "BucketNameHMAC"):
                    copy(key)
            elif cloud["AccountType"] == "SA":
                copy("BucketNameSA")
                copy("ServiceAccountJsonFileName")
                jsonString = qv_to_str(cloudConfig.get("ServiceAccountJsonFile"))  # Raw JSON
                encoded = base64.b64encode(jsonString.encode("utf-8")).decode("ascii")
                cloud["ServiceAccountJsonFile"] = c_str(encoded, sizes["ServiceAccountJsonFile"])
        elif branch == "azure":
            for key in ("AccountType", "AzureAccountName", "AzureAccountKey", "AzureContainerName"):
                copy(key)
        else:
            for key in ("AccessKey", "SecretKey", "Region", "BucketName"):
                copy(key)

        return self.wifiOnvifModel.setServerConfig(serverData) == 1

    @pyqtSlot(result="QVariantMap")
    def getTimerConfigMap(self) -> dict:
        timerConfigMap: dict = {}
        result, timer = self.wifiOnvifModel.getTimerConfig()
        if result == 1:
            start, end, duration = timer["startTime"], timer["endTime"], timer["duration"]
            childrenList = [
                {"label": "Start Time", "value": "Start Time",
                 "startHour": start["hours"], "startMin": start["minutes"],
                 "startSec": start["seconds"], "editable": True},
                {"label": "End Time", "value": "End Time",
                 "endHour": end["hours"], "endMin": end["minutes"],
                 "endSec": end["seconds"], "editable": True},
                {"label": "Duration", "value": "TimetextBox",
                 "hour": str(duration["hours"]), "min": str(duration["minutes"]),
                 "sec": str(duration["seconds"]), "editable": True},
                {"label": "Format", "value": "dropBox", "enabled": True,
                 "children_drop": [{"label1": "MJPG"}, {"label1": "YUV"}],
                 "selected": "MJPG" if timer["imageType"] == 1 else "YUV"},
            ]
            timerConfigMap["children"] = childrenList
        else:
            _log.debug("Error: Failed to retrieve Timer configuration.")
        return timerConfigMap

    @pyqtSlot("QVariantMap", result=bool)
    def setTimerConfigMap(self, timerConfigMap: dict) -> bool:
        timerData = {"startTime": {"hours": 0, "minutes": 0, "seconds": 0},
                     "endTime": {"hours": 0, "minutes": 0, "seconds": 0},
                     "duration": {"hours": 0, "minutes": 0, "seconds": 0},
                     "imageType": 0}
        for child in qv_to_list(timerConfigMap.get("children")):
            childMap = qv_to_map(child)
            label = qv_to_str(childMap.get("label"))
            if label == "Start Time":
                t = timerData["startTime"]
                t["hours"] = qv_to_int(childMap.get("startHour"))
                t["minutes"] = qv_to_int(childMap.get("startMin"))
                t["seconds"] = qv_to_int(childMap.get("startSec"))
            elif label == "End Time":
                t = timerData["endTime"]
                t["hours"] = qv_to_int(childMap.get("endHour"))
                t["minutes"] = qv_to_int(childMap.get("endMin"))
                t["seconds"] = qv_to_int(childMap.get("endSec"))
            elif label == "Duration":
                t = timerData["duration"]
                t["hours"] = qv_to_int(childMap.get("hour"))
                t["minutes"] = qv_to_int(childMap.get("min"))
                t["seconds"] = qv_to_int(childMap.get("sec"))
            elif label == "Format":
                # WifiSettings.qml sends the chosen format back as "value".
                selectedFormat = qv_to_str(childMap.get("value"))
                if selectedFormat == "YUV":
                    timerData["imageType"] = 0
                elif selectedFormat == "MJPG":
                    timerData["imageType"] = 1
        return self.wifiOnvifModel.setTimerConfig(timerData) == 1

    @pyqtSlot(result=int)
    def snapshotWorker(self) -> int:
        result, data = self.wifiOnvifModel.setSnapshotConfig()
        if result == 1 and len(data["bufferData"]) > 0 and data["bufferDataSize"] > 0:
            timestamp = QDateTime.currentDateTime().toString("yyyy-MM-dd_HH-mm-ss")
            filename = (f"snapshot_{timestamp}.raw" if data["imageType"] == 0
                        else f"snapshot_{timestamp}.jpg")
            savePath = desktop_location() + "/" + filename
            try:
                with open(savePath, "wb") as fh:
                    fh.write(bytes(data["bufferData"])[: max(0, int(data["bufferDataSize"]))])
                return 1
            except OSError:
                _log.warning("Failed to open file for writing: %s", savePath)
                return 0
        _log.warning("Snapshot failed or data invalid.")
        return 0

    @pyqtSlot(str, result=bool)
    def readSAJsonArrayFile(self, filepath: str) -> bool:
        opened, doc, err = read_json_document(filepath)
        if not opened:
            self.jsonFileReadFailed.emit("Error: Failed to open file.")
            _log.debug("Failed to open the file: %s", err)
            return False
        if doc.isNull():
            self.jsonFileReadFailed.emit("Error: Failed to parse JSON. Please provide a valid json file.")
            _log.debug("Failed to parse JSON.")
            return False
        if doc.isObject():
            self.saJsonFileContent.emit(doc.toVariant())
        else:
            self.jsonFileReadFailed.emit("Error: Invalid file format. Please provide a valid json file")
            _log.debug("The JSON is not an array.")
            return False
        return True

    @pyqtSlot(str, str, bool, result=bool)
    def readAzureJsonFile(self, fileName: str, filepath: str, isSAS: bool) -> bool:
        opened, doc, err = read_json_document(filepath)
        if not opened:
            self.jsonFileReadFailed.emit("Error: Failed to open file.")
            _log.debug("Failed to open the file: %s", err)
            return False
        if doc.isNull() or not doc.isObject():
            self.jsonFileReadFailed.emit(
                "Error: Invalid JSON or not a JSON object. Please provide a valid json file.")
            _log.debug("Invalid JSON or not a JSON object.")
            return False

        jsonObj = doc.object()

        def string_value(key: str):
            value = jsonObj.get(key)
            if isinstance(value, QJsonValue) and value.isString():
                return value.toString()
            return None

        if self.isSASTokenAvailable and isSAS:
            sharedKey = string_value("sas_token")
            if sharedKey is None:
                self.jsonFileReadFailed.emit("Error: sas_token not found. Please provide a valid json")
                _log.debug("sas_token not found or is not a string.")
                return False
        else:
            sharedKey = string_value("shared_key")
            if sharedKey is None:
                self.jsonFileReadFailed.emit("Error: shared_key not found. Please provide a valid json.")
                _log.debug("shared_key not found or is not a string.")
                return False
        self.azureJsonFileRead.emit(fileName, sharedKey)
        return True

    @pyqtSlot(result="QVariantMap")
    def getCameraConfigMap(self) -> dict:
        infoMap: dict = {}
        result, info = self.wifiOnvifModel.getCameraConfigSettings()

        def prop(p: int) -> dict:
            # std::map::operator[] inserts a value-initialised Range if missing.
            return info["property"].setdefault(p, dict(RANGE))

        def addProperty(key: str, rng: dict) -> None:
            infoMap[key] = {"current": rng["current"], "min": rng["min"], "max": rng["max"]}

        if result == 1:
            antiBanding = prop(P.AntiBanding)["current"]
            if antiBanding == 0:
                infoMap["antiBanding"] = "60Hz"
            elif antiBanding == 1:
                infoMap["antiBanding"] = "50Hz"

            addProperty("qFactor", prop(P.QFactor))

            if self.isOEM:
                addProperty("frameRate", prop(P.FrameRate))
                addProperty("brightness", prop(P.Brightness))
                addProperty("contrast", prop(P.Contrast))
                addProperty("saturation", prop(P.Saturation))
                addProperty("sharpness", prop(P.Sharpness))
                addProperty("zoom", prop(P.Zoom))
                addProperty("exposureMode", prop(P.ExposureMode))
                addProperty("exposure", prop(P.Exposure))
                addProperty("Gain", prop(P.Gain))
                addProperty("wbMode", prop(P.WBMode))
        else:
            _log.debug("Error: Failed to retrieve camera config information.")
        return infoMap

    @pyqtSlot(str, int, result=bool)
    def setCamConfig(self, identifier: str, value: int) -> bool:
        if self.wifiOnvifModel.setCamConfigSettings(identifier, value) == 1:
            return True
        _log.debug("Error: Failed to set Camera Configuration settings.")
        return False

    @pyqtSlot(result=int)
    def getAvailableResolutions(self) -> int:
        if self.wifiOnvifModel.getAvailableResolutions() == 1:
            return 1
        _log.debug("Error: Failed to retrieve available resolutions.")
        return 0

    @pyqtSlot(result=int)
    def getCurrentResolution(self) -> int:
        if self.wifiOnvifModel.getResolution() == 1:
            return 1
        _log.debug("Error: Failed to retrieve available resolutions.")
        return 0

    @pyqtSlot(str, result=int)
    def setCurrentResolution(self, resolution: str) -> int:
        if self.wifiOnvifModel.setResolution(resolution) == 1:
            # adapter_report(self.diagnosticsControlAdapter, "reportResolution", resolution)
            return 1
        _log.debug("Error: Failed to set resolutions.")
        return 0

    @pyqtSlot(result=int)
    def powerOff(self) -> int:
        return self.wifiOnvifModel.powerOff()

    @pyqtSlot(result=int)
    def startRecording(self) -> int:
        result = self.wifiOnvifModel.startRecording()
        # if result == 1:
        #     adapter_report(self.diagnosticsControlAdapter, "reportRecordingState", True)
        return result

    @pyqtSlot(result=int)
    def stopRecording(self) -> int:
        result = self.wifiOnvifModel.stopRecording()
        # if result == 1:
        #     adapter_report(self.diagnosticsControlAdapter, "reportRecordingState", False)
        return result

    def _write_key_file(self, filename: str, keyName: str, sharedKey: str, status_prefix: str,
                        write_error: str) -> int:
        jsonData = QJsonDocument({keyName: QJsonValue(sharedKey)}).toJson(QJsonDocument.Indented)

        if not (sys.platform.startswith("linux") or sys.platform == "win32"):
            _log.warning("Unsupported OS")
            return -1
        downloadsPath, sudoUser = downloads_location()

        if not downloadsPath:
            _log.warning("Could not resolve Downloads directory")
            return -2

        # Ensure Downloads directory exists
        qdir = QDir()
        if not qdir.exists(downloadsPath):
            if not qdir.mkpath(downloadsPath):
                _log.warning("Failed to create Downloads directory: %s", downloadsPath)
                return -3

        filePath = downloadsPath + QDir.separator() + filename

        f = QFile(filePath)
        if not f.open(QIODevice.WriteOnly | QIODevice.Truncate):
            _log.warning("%s %s", write_error, f.errorString())
            return -4
        f.write(jsonData)
        f.close()

        if sys.platform.startswith("linux") and sudoUser:
            # Fix ownership ONLY when running with sudo
            os.system(f'chown {sudoUser}:{sudoUser} "{filePath}"')

        self.statusChanged.emit(status_prefix + filePath)
        return 0

    @pyqtSlot(str, result=int)
    def downloadSharedKeyFile(self, sharedKey: str) -> int:
        timestamp = QDateTime.currentDateTime().toString("yyyyMMdd_HHmmss")
        return self._write_key_file(f"shared_key_{timestamp}.json", "shared_key", sharedKey,
                                    "Key file saved to Downloads: ", "Failed to write file:")

    @pyqtSlot(bool, str, result=int)
    def downloadSasKeyFile(self, isSAS: bool, sharedKey: str) -> int:
        timestamp = QDateTime.currentDateTimeUtc().toString("yyyyMMdd_HHmmss")
        if isSAS:
            filename, keyName = f"sas_token_{timestamp}.json", "sas_token"
        else:
            filename, keyName = f"shared_key_{timestamp}.json", "shared_key"
        return self._write_key_file(filename, keyName, sharedKey, "Key file saved: ",
                                    "Failed to write JSON file:")

    @pyqtSlot(result="QVariantMap")
    def getSDCardInfoMap(self) -> dict:
        infoMap: dict = {}
        result, info = self.wifiOnvifModel.getSDCardInfo()
        if result == 1:
            infoMap["message"] = info["Message"]
            infoMap["totalGb"] = info["totlGB"]
            infoMap["freeGb"] = info["freeGb"]
            infoMap["usedGb"] = info["usedGb"]
            infoMap["status"] = info["status"]
        else:
            _log.debug("Error: Failed to retrieve sd card information.")
        return infoMap

    @staticmethod
    def _format_event_duration(seconds: int) -> str:
        return f"{seconds} sec" if seconds < 60 else f"{c_div(seconds, 60)} min"

    @pyqtSlot(result="QVariantMap")
    def getVidRecConfigMap(self) -> dict:
        infoMap: dict = {}
        result, info = self.wifiOnvifModel.getVidRecConfiguration()
        if result == 1:
            infoMap["circularRecording"] = "Enable" if info["isCircularRecordingEnable"] else "Disable"
            infoMap["eventRecording"] = "Enable" if info["isEventRecordingEnable"] else "Disable"
            infoMap["vidRecDuration"] = int(info["recordingDuration"])
            infoMap["preEventDuration"] = self._format_event_duration(int(info["preEventDuration"]))
            infoMap["postEventDuration"] = self._format_event_duration(int(info["postEventDuration"]))
        else:
            _log.debug("Error: Failed to retrieve video record configurations")
        return infoMap

    @pyqtSlot(result=int)
    def setDefaultResolution(self) -> int:
        result = self.wifiOnvifModel.setDefaultResolution()
        # if result == 1:
        #     adapter_report(self.diagnosticsControlAdapter, "reportResolution", "Default")
        return result

    @staticmethod
    def _parse_event_duration(value) -> int | None:
        match = _DURATION_RE.search(qv_to_str(value).lower())  # e.g. "10 min"
        if not match:
            return None
        duration = qstr_to_int(match.group(1))
        if match.group(2).startswith("min"):
            duration *= 60  # convert minutes -> seconds
        return duration  # ALWAYS in seconds

    @pyqtSlot("QVariantMap", result=bool)
    def setRecordingConfig(self, recConfigMap: dict) -> bool:
        recConfData = {"recordingDuration": 0, "isCircularRecordingEnable": False,
                       "isEventRecordingEnable": False, "preEventDuration": 0,
                       "postEventDuration": 0}
        circular = qv_to_str(recConfigMap.get("circularRecording"))
        if circular == "Enable":
            recConfData["isCircularRecordingEnable"] = True
        elif circular == "Disable":
            recConfData["isCircularRecordingEnable"] = False
        event = qv_to_str(recConfigMap.get("eventRecording"))
        if event == "Enable":
            recConfData["isEventRecordingEnable"] = True
        elif event == "Disable":
            recConfData["isEventRecordingEnable"] = False
        recConfData["recordingDuration"] = qv_to_int(recConfigMap.get("vidRecDuration"))

        post = self._parse_event_duration(recConfigMap.get("postEventDuration"))
        if post is not None:
            recConfData["postEventDuration"] = post
        pre = self._parse_event_duration(recConfigMap.get("preEventDuration"))
        if pre is not None:
            recConfData["preEventDuration"] = pre

        if self.wifiOnvifModel.setRecordingTimerConfig(recConfData) == 1:
            return True
        _log.debug("Error: Failed to set RecordingConfig.")
        return False

    @pyqtSlot(result=int)
    def ejectSDCard(self) -> int:
        return self.wifiOnvifModel.ejectSDCard()

    @pyqtSlot(result=int)
    def setCameraConfigDefault(self) -> int:
        return self.wifiOnvifModel.setCameraConfigDefault()

    @pyqtSlot(result=str)
    def getWhiteBalance(self) -> str:
        result, whiteBalance = self.wifiOnvifModel.getWhiteBalanceSettings()
        if result == 1:
            return whiteBalance
        _log.debug("Error: Failed to retrieve White Balance.")
        return ""

    @pyqtSlot(result=str)
    def getRecordingStatus(self) -> str:
        result, recordingStatus = self.wifiOnvifModel.getRecordingStatusSettings()
        if result == 1:
            return recordingStatus
        _log.debug("Error: Failed to retrieve Recording Status.")
        return ""

    @pyqtSlot(str, result=bool)
    def setWhiteBalance(self, whiteBalance: str) -> bool:
        if self.wifiOnvifModel.setWhiteBalanceSettings(whiteBalance) == 1:
            return True
        _log.debug("Error: Failed to set White Balance.")
        return False

    @pyqtSlot(int, result="QVariantMap")
    def setPan(self, pan: int) -> dict:
        result, msg = self.wifiOnvifModel.setPan(pan)
        if result == 1:
            # adapter_report(self.diagnosticsControlAdapter, "reportPan", pan)
            return {"success": True, "message": msg}
        return {"success": False, "message": msg}

    @pyqtSlot(int, result="QVariantMap")
    def setTilt(self, tilt: int) -> dict:
        result, msg = self.wifiOnvifModel.setTilt(tilt)
        if result == 1:
            # adapter_report(self.diagnosticsControlAdapter, "reportTilt", tilt)
            return {"success": True, "message": msg}
        return {"success": False, "message": msg}
