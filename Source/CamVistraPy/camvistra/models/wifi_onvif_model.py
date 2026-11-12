"""ShelfVista (Wi-Fi) ONVIF camera model.

Port of CamVistra/Model/include/WifiOnvifModel.h and
CamVistra/Model/src/WifiOnvifModel.cpp.

The C++ model passes SDK structs by pointer; here every getter returns
``(result, struct_dict)`` (dicts keyed by the C++ field names, exactly as the
``camvistra._native`` binding produces them) and every setter takes such a
dict. ``result`` is the C++ model's int (1 = success, 0 = failure).

Threading: as in the C++ build every call runs synchronously on the calling
(GUI) thread - the C++ WifiOnvifController never moves this model to a worker.

This module also hosts small ``QVariant`` conversion helpers (``qv_*``) that
reproduce QVariant::toInt()/toString()/toBool() semantics for values coming
from QML; the Routecam controller reuses them.
"""

from __future__ import annotations

import copy
import logging
import math
import re
import time

from PyQt5.QtCore import QDateTime, QObject, Qt, QTimeZone, pyqtSignal

_log = logging.getLogger(__name__)

_INT_RE = re.compile(r"^[+-]?\d+$")
_INT_MIN, _INT_MAX = -(2 ** 31), 2 ** 31 - 1

_UNSET = object()


# ---------------------------------------------------------------------------
# QVariant / QString conversion helpers (Qt 5.15 semantics)
# ---------------------------------------------------------------------------

def qstr_to_int(text: str) -> int:
    """QString::toInt(): surrounding whitespace allowed, 0 on failure/overflow."""
    s = str(text).strip()
    if not _INT_RE.match(s):
        return 0
    value = int(s)
    return value if _INT_MIN <= value <= _INT_MAX else 0


def fmt_number(value) -> str:
    """QString::number(double) formatting (%g with 6 significant digits).

    SDK ``float`` fields arrive as Python floats: ``f"{30.0}"`` gives "30.0"
    where C++ gives "30", and qstr_to_int("30.0") then returns 0.
    """
    return f"{value:g}" if isinstance(value, float) else str(value)


def qv_to_int(value) -> int:
    """QVariant::toInt() for values arriving from QML/JS."""
    if value is None:
        return 0
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return int(value)
    if isinstance(value, float):
        if math.isnan(value) or math.isinf(value):
            return 0
        return int(math.floor(value + 0.5))  # qRound64
    if isinstance(value, str):
        return qstr_to_int(value)
    return 0


def qv_to_str(value) -> str:
    """QVariant::toString() for values arriving from QML/JS."""
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float):
        if value.is_integer() and abs(value) < 1e16:
            return str(int(value))
        return repr(value)
    if isinstance(value, (int, str)):
        return str(value)
    return ""


def qv_to_bool(value) -> bool:
    """QVariant::toBool() for values arriving from QML/JS."""
    if value is None:
        return False
    if isinstance(value, str):
        return value != "" and value != "0" and value.lower() != "false"
    if isinstance(value, (bool, int, float)):
        return bool(value)
    return False


def qv_to_map(value) -> dict:
    return dict(value) if isinstance(value, dict) else {}


def qv_to_list(value) -> list:
    return list(value) if isinstance(value, (list, tuple)) else []


def c_str(text: str, size: int) -> str:
    """Emulate ``strncpy(dst, text.toUtf8(), size - 1)`` into a zeroed char[size]."""
    raw = str(text).encode("utf-8").split(b"\0", 1)[0][: size - 1]
    return raw.decode("utf-8", "ignore")


def c_div(a: int, b: int) -> int:
    """C++ integer division (truncates toward zero)."""
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b >= 0) else -q


# ---------------------------------------------------------------------------
# SDK result helpers
# ---------------------------------------------------------------------------

def sdk_result(ret) -> tuple[int, tuple]:
    """Split a binding return value into ``(int result, out_values)``."""
    if isinstance(ret, tuple):
        head = ret[0] if ret else 0
        return _as_int(head), tuple(ret[1:])
    return _as_int(ret), ()


def _as_int(value) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def merge_struct(defaults: dict, value) -> dict:
    """Zero-initialised struct ``defaults`` overlaid with ``value`` (recursive)."""
    out = copy.deepcopy(defaults)
    if isinstance(value, dict):
        for key, val in value.items():
            if key in out and isinstance(out[key], dict) and isinstance(val, dict) \
                    and key not in _MAP_FIELDS:
                out[key] = merge_struct(out[key], val)
            else:
                out[key] = val
    return out


def out_struct(outs: tuple, index: int, defaults: dict) -> dict:
    return merge_struct(defaults, outs[index] if len(outs) > index else None)


def out_value(outs: tuple, index: int, default):
    return outs[index] if len(outs) > index and outs[index] is not None else default


# std::map fields: merged as a whole, never key-by-key.
_MAP_FIELDS = {"property", "defaultCameraConfigValues", "defaultCameraPropertyValues"}


# ---------------------------------------------------------------------------
# ShelfVista_Enums.h
# ---------------------------------------------------------------------------

class CameraConfigProperty:
    Brightness = 0
    Contrast = 1
    FrameRate = 2
    Saturation = 3
    Sharpness = 4
    ExposureMode = 5
    Exposure = 6
    Gain = 7
    Zoom = 8
    WBMode = 9
    AntiBanding = 10
    QFactor = 11


P = CameraConfigProperty

K_PROPERTY_TO_UI_ID = {
    P.AntiBanding: "Anti-Banding",
    P.QFactor: "Quantization",
    P.FrameRate: "frameRate",
    P.Brightness: "brightness",
    P.Sharpness: "sharpness",
    P.Saturation: "saturation",
    P.Contrast: "contrast",
    P.Zoom: "zoom",
    P.WBMode: "wbMode",
    P.Exposure: "exposure",
    P.ExposureMode: "exposureMode",
    P.Gain: "gain",
}

_IDENTIFIER_TO_PROPERTY = {
    "frameRate": P.FrameRate,
    "contrast": P.Contrast,
    "brightness": P.Brightness,
    "saturation": P.Saturation,
    "sharpness": P.Sharpness,
    "zoom": P.Zoom,
    "exposureMode": P.ExposureMode,
    "exposure": P.Exposure,
    "gain": P.Gain,
    "wbMode": P.WBMode,
}

# Zero-initialised SDK structs (field names as in ShelfVista_Enums.h).
DATE_TIME_CHAR_SIZE = 100  # DateTime: char hour[100], ..., timeZone[100]
DEVICE_INFORMATION = dict(manufacturer="", model="", firmwareVersion="", serialNumber="",
                          hardwareId="", last_error="")
BATTERY_STATUS = dict(batteryStatus="", chargingStatus="")
CAPABILITIES = dict.fromkeys(
    ("HMAC", "ServiceAccount", "Azure", "SASToken", "OEM", "Brightness", "Contrast",
     "ExposureMode", "Pan", "FPS", "Sharpness", "Saturation", "WhiteBalanceMode", "Tilt",
     "Zoom", "Trigger", "BatteryStatus"), False)
AP_DATA = dict(SSID="", password="", securityMode="", band=0, channel=0)
STA_DATA = dict.fromkeys(("SSID", "password", "ipConfig", "ipAddress", "subnetMask",
                          "gateway", "primaryDNS"), "")
LOCAL_CONFIG = dict(IP="", Port=0)
CLOUD_CONFIG = dict.fromkeys(
    ("AccountName", "AccountType", "Provider", "AccessKey", "SecretKey", "Region",
     "BucketName", "BucketNameHMAC", "BucketNameSA", "ServiceAccountJsonFileName",
     "ServiceAccountJsonFile", "AzureAccountName", "AzureContainerName", "AzureAccountKey"), "")
SERVER_DATA = dict(mode=False, localConfig=LOCAL_CONFIG, cloudConfig=CLOUD_CONFIG)
TIME = dict(hours=0, minutes=0, seconds=0)
TIMER_DATA = dict(startTime=TIME, endTime=TIME, duration=TIME, imageType=0)
CAMERA_CONFIG = dict(qFactor=0, antibanding=0)
SNAPSHOT_DATA = dict(bufferData=[], bufferDataSize=0, imageType=0)
RESOLUTION = dict(width=0, height=0)
RANGE = dict(min=0, max=0, current=0, defaultValue=0)
CAMERA_CONFIG_RANGE = dict(property={})
SD_CARD_INFO = dict.fromkeys(("totlGB", "freeGb", "usedGb", "status", "Message"), "")
RECORDING_CONFIG = dict(recordingDuration=0, isCircularRecordingEnable=False,
                        isEventRecordingEnable=False, preEventDuration=0, postEventDuration=0)

# char[N] / std::array<char, N> sizes used by the controller's strncpy calls.
CHAR_SIZES = {
    "AP": dict(SSID=128, password=128, securityMode=32),
    "STA": dict(SSID=128, password=128, ipConfig=32, ipAddress=32, subnetMask=32,
                gateway=32, primaryDNS=32),
    "LOCAL": dict(IP=256),
    "CLOUD": {**dict.fromkeys(CLOUD_CONFIG, 256), "ServiceAccountJsonFile": 4096},
}


def _default_client():
    from camvistra.native import sdk
    return sdk.getShelfVistaOnvifInstance()


class WifiOnvifModel(QObject):
    statusChanged = pyqtSignal(str)
    onvifInitialized = pyqtSignal()
    currentResolutionReceived = pyqtSignal(str)
    availableResolutionsList = pyqtSignal("QVariantList")
    defaultResolution = pyqtSignal(str)
    sdCardEjected = pyqtSignal()
    defaultUiValues = pyqtSignal("QVariantMap")
    sdCardInfo = pyqtSignal(str)

    def __init__(self, client=_UNSET, parent: QObject | None = None) -> None:
        super().__init__(parent)
        # ``client`` lets tests inject a fake IShelfVistaOnvifClient.
        self.shelfVistaOnvif = _default_client() if client is _UNSET else client
        # CameraConfigDefaultValues::defaultCameraConfigValues (std::map).
        self.defaultValues: dict[int, int] = {}
        self.defaultWbValue = ""
        # IP addresses whose date/time has already been set this session.
        self.dateTimeSyncedCameras: set[str] = set()

    # ------------------------------------------------------------------
    def initializeOnvif(self, ipAddress: str) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("shelfVistaOnvif is null")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.initialize(ipAddress))
        if result == 1:
            # Must run before onvifInitialized(): its QML handler issues all the get requests.
            self.syncDateTimeOnce(ipAddress)
            self.onvifInitialized.emit()
            return 1
        return 0

    def syncDateTimeOnce(self, ipAddress: str) -> None:
        """Push the host's UTC date/time and time zone to the camera, once per camera.

        The time zone is sent as "UTC+H:MM" from the host's standard offset,
        with the daylight-savings flag set separately (as in C++).
        """
        if ipAddress in self.dateTimeSyncedCameras:
            return

        nowUtc = QDateTime.currentDateTimeUtc()
        systemZone = QTimeZone.systemTimeZone()

        offsetSecs = systemZone.standardTimeOffset(nowUtc)
        absOffsetMins = abs(offsetSecs) // 60
        timeZone = "UTC%s%d:%02d" % ("-" if offsetSecs < 0 else "+",
                                     absOffsetMins // 60, absOffsetMins % 60)

        size = DATE_TIME_CHAR_SIZE
        t, d = nowUtc.time(), nowUtc.date()
        settings = {
            "hour": c_str(str(t.hour()), size),
            "minute": c_str(str(t.minute()), size),
            "second": c_str(str(t.second()), size),
            "year": c_str(str(d.year()), size),
            "month": c_str(str(d.month()), size),
            "day": c_str(str(d.day()), size),
            "timeZone": c_str(timeZone, size),
            "daylightSavings": bool(systemZone.isDaylightTime(nowUtc)),
        }

        result, _ = sdk_result(self.shelfVistaOnvif.setDateTime(settings))
        if result == 1:
            self.dateTimeSyncedCameras.add(ipAddress)
            _log.debug("Camera date/time set to %s %s", nowUtc.toString(Qt.ISODate), timeZone)
        else:
            _log.debug("setDateTime failed; will retry on the next connection")

    def getDeviceInformation(self) -> tuple[int, dict]:
        info = dict(DEVICE_INFORMATION)
        if self.shelfVistaOnvif is None:
            info["last_error"] = "Onvif not initialized"
            return 0, info
        result, outs = sdk_result(self.shelfVistaOnvif.getDeviceInformation(info))
        info = out_struct(outs, 0, info)
        if result == 1:
            return 1, info
        if info["last_error"] == "":
            info["last_error"] = "Failed to get device information"
        return 0, info

    def getBatteryStatus(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, dict(BATTERY_STATUS)
        result, outs = sdk_result(self.shelfVistaOnvif.getBatteryStatus())
        info = out_struct(outs, 0, BATTERY_STATUS)
        if result == 1:
            return 1, info
        _log.debug("getBatteryStatus failed")
        return 0, info

    def getCapabilities(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, dict(CAPABILITIES)
        result, outs = sdk_result(self.shelfVistaOnvif.getCapabilities())
        caps = out_struct(outs, 0, CAPABILITIES)
        if result == 1:
            return 1, caps
        _log.debug("getCapabilities failed")
        return 0, caps

    def getAPConfig(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, dict(AP_DATA)
        result, outs = sdk_result(self.shelfVistaOnvif.getAPConfig())
        data = out_struct(outs, 0, AP_DATA)
        if result == 1:
            return 1, data
        _log.debug("getAPConfig failed")
        return 0, data

    def setAPConfig(self, apData: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setAPConfig(apData))
        if result == 1:
            self.statusChanged.emit("AP Config saved successfully")
            return 1
        self.statusChanged.emit("AP Config save failed")
        return 0

    def setCameraConfigSettings(self, camConfig: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setCameraConfig(camConfig))
        if result == 1:
            self.statusChanged.emit("Camera Config saved successfully")
            return 1
        self.statusChanged.emit("Camera Config save failed")
        return 0

    def getSTAConfig(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, dict(STA_DATA)
        result, outs = sdk_result(self.shelfVistaOnvif.getSTAConfig())
        data = out_struct(outs, 0, STA_DATA)
        if result == 1:
            return 1, data
        _log.debug("getSTAConfig failed")
        return 0, data

    def setSTAConfig(self, staData: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setSTAConfig(staData))
        if result == 1:
            self.statusChanged.emit("STA Config saved successfully")
            return 1
        self.statusChanged.emit("STA Config save failed")
        return 0

    def getServerConfig(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, merge_struct(SERVER_DATA, None)
        result, outs = sdk_result(self.shelfVistaOnvif.getServerConfig())
        data = out_struct(outs, 0, SERVER_DATA)
        if result == 1:
            return 1, data
        _log.debug("getServerConfig failed")
        return 0, data

    def setServerConfig(self, serverData: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setServerConfig(serverData))
        if result == 1:
            self.statusChanged.emit("Server Config saved successfully")
        else:
            self.statusChanged.emit("Server Config save failed")
            return 0
        return 1

    def getTimerConfig(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, merge_struct(TIMER_DATA, None)
        result, outs = sdk_result(self.shelfVistaOnvif.getTimerConfig())
        data = out_struct(outs, 0, TIMER_DATA)
        if result != 1:
            _log.debug("getTimerConfig failed")
            return 0, data
        return 1, data

    def setTimerConfig(self, timerData: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setTimerConfig(timerData))
        if result == 1:
            self.statusChanged.emit("Timer Config saved successfully")
        else:
            self.statusChanged.emit("Timer Config save failed")
            return 0
        return 1

    def reboot(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.systemReboot())
        if result == 1:
            self.statusChanged.emit("System Reboot succeeded")
        else:
            self.statusChanged.emit("System Reboot failed")
            return 0
        return 1

    def setSnapshotConfig(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, merge_struct(SNAPSHOT_DATA, None)
        start = time.perf_counter()
        result, outs = sdk_result(self.shelfVistaOnvif.setSnapshotConfig())
        data = out_struct(outs, 0, SNAPSHOT_DATA)
        if result == 1:
            if len(data["bufferData"]) > 0 and data["bufferDataSize"] > 0:
                elapsed = time.perf_counter() - start
                self.statusChanged.emit(f"Snapshot captured in {elapsed:.3f}s")
                return 1, data
            self.statusChanged.emit("Snapshot failed")
            return 0, data
        self.statusChanged.emit("Snapshot failed")
        return 0, data

    def getCameraConfigSettings(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, merge_struct(CAMERA_CONFIG_RANGE, None)
        result, outs = sdk_result(self.shelfVistaOnvif.getCameraConfig())
        cfg = out_struct(outs, 0, CAMERA_CONFIG_RANGE)
        cfg["property"] = {int(k): merge_struct(RANGE, v)
                           for k, v in dict(cfg.get("property") or {}).items()}
        if result == 1:
            # Fill default values from ranges (std::map -> sorted by property).
            self.defaultValues = {}
            for prop in sorted(cfg["property"]):
                rng = cfg["property"][prop]
                if rng["min"] <= rng["defaultValue"] <= rng["max"]:
                    self.defaultValues[prop] = rng["defaultValue"]
                else:
                    self.defaultValues[prop] = rng["min"]
            return 1, cfg
        _log.debug("getCameraConfigSettings failed")
        return 0, cfg

    def setCamConfigSettings(self, identifier: str, value: int) -> int:
        prop = P.FrameRate
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        prop = _IDENTIFIER_TO_PROPERTY.get(identifier, prop)
        result, _ = sdk_result(self.shelfVistaOnvif.setCamConfig(prop, int(value)))
        if result == 1:
            self.statusChanged.emit("Camera config updated successfully")
            return 1
        _log.debug("setCamConfig failed")
        return 0

    def getAvailableResolutions(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        result, outs = sdk_result(self.shelfVistaOnvif.getAvailableResolutions())
        if result == 1:
            resolutions = out_value(outs, 0, [])
            items = [merge_struct(RESOLUTION, r) for r in resolutions]
            self.availableResolutionsList.emit([f"{r['width']}x{r['height']}" for r in items])
            return 1
        _log.debug("getAvailableResolutions failed")
        return 0

    def getResolution(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        result, outs = sdk_result(self.shelfVistaOnvif.getResolution())
        if result == 1:
            res = out_struct(outs, 0, RESOLUTION)
            self.currentResolutionReceived.emit(f"{res['width']}x{res['height']}")
            return 1
        _log.debug("getResolution failed")
        return 0

    def setResolution(self, resolution: str) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        resln = dict(RESOLUTION)
        parts = [p for p in resolution.split("x") if p]
        if len(parts) == 2:
            resln["width"] = qstr_to_int(parts[0])
            resln["height"] = qstr_to_int(parts[1])
        result, _ = sdk_result(self.shelfVistaOnvif.setResolution(resln))
        if result == 1:
            self.statusChanged.emit("Resolution switched successfully")
            return 1
        _log.debug("setResolution failed")
        return 0

    def powerOff(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.systemPowerOff())
        if result == 1:
            self.statusChanged.emit("System Power Off succeeded")
        else:
            self.statusChanged.emit("System Power Off failed")
            return 0
        return 1

    def startRecording(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.startRecording())
        if result == 1:
            return 1
        self.statusChanged.emit("Failed to start recording")
        return 0

    def stopRecording(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.stopRecording())
        if result == 1:
            self.statusChanged.emit("Recording successfully saved")
        else:
            self.statusChanged.emit("Failed to stop recording")
            return 0
        return 1

    def getSDCardInfo(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, dict(SD_CARD_INFO)
        result, outs = sdk_result(self.shelfVistaOnvif.readSDCardInfo())
        info = out_struct(outs, 0, SD_CARD_INFO)
        if result == 1:
            return 1, info
        _log.debug("Failed to read SD card info")
        return 0, info

    def getVidRecConfiguration(self) -> tuple[int, dict]:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0, dict(RECORDING_CONFIG)
        result, outs = sdk_result(self.shelfVistaOnvif.getRecordingConfig())
        info = out_struct(outs, 0, RECORDING_CONFIG)
        if result == 1:
            return 1, info
        _log.debug("Failed to getVidRecConfiguration")
        return 0, info

    def setDefaultResolution(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, outs = sdk_result(self.shelfVistaOnvif.setDefaultResolution(dict(RESOLUTION)))
        if result == 1:
            resln = out_struct(outs, 0, RESOLUTION)
            self.statusChanged.emit("Default resolution set successfully")
            self.defaultResolution.emit(f"{resln['width']}x{resln['height']}")
            return 1
        _log.debug("Failed to setDefaultResolution")
        return 0

    def setRecordingTimerConfig(self, info: dict) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setRecordingConfig(info))
        if result == 1:
            self.statusChanged.emit("Recording Timer Configuration set successfully")
            return 1
        self.statusChanged.emit("Set Recording Timer Configuration failed")
        return 0

    def ejectSDCard(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.ejectSDCard(""))
        if result == 1:
            self.statusChanged.emit("SD Card ejected successfully")
            self.sdCardEjected.emit()
            info_result, outs = sdk_result(self.shelfVistaOnvif.readSDCardInfo())
            if info_result == 1:
                self.sdCardInfo.emit(out_struct(outs, 0, SD_CARD_INFO)["Message"])
            return 1
        self.statusChanged.emit("Eject SD card failed")
        return 0

    def setCameraConfigDefault(self) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("Onvif not initialized")
            return 0
        uiValues: dict[str, object] = {}
        for prop in sorted(self.defaultValues):
            value = self.defaultValues[prop]
            if prop not in K_PROPERTY_TO_UI_ID:
                continue
            uiId = K_PROPERTY_TO_UI_ID[prop]
            if prop == P.AntiBanding:
                uiValues[uiId] = "50Hz" if value == 1 else "60Hz"
            elif prop in (P.ExposureMode, P.WBMode):
                uiValues[uiId] = "MANUAL" if value == 1 else "AUTO"
            else:
                uiValues[uiId] = value

        # Add white balance default
        uiValues["whiteBalance"] = self.defaultWbValue

        # Emit to QML (QVariantMap -> sorted keys, like QMap)
        self.defaultUiValues.emit(dict(sorted(uiValues.items())))

        # Both SDK calls take their argument by non-const reference in C++;
        # write the (possibly updated) values back like the C++ members.
        wb_result, wb_outs = sdk_result(self.shelfVistaOnvif.setWhiteBalance(self.defaultWbValue))
        self.defaultWbValue = out_value(wb_outs, 0, self.defaultWbValue)
        if wb_result == 1:
            self.statusChanged.emit("Default Camera Config values set successfully")
        else:
            self.statusChanged.emit("Set Default Camera Config values failed")

        defaults = {"defaultCameraConfigValues": dict(self.defaultValues)}
        result, def_outs = sdk_result(self.shelfVistaOnvif.setDefaultConfiguration(defaults))
        if len(def_outs) > 0 and isinstance(def_outs[0], dict) \
                and isinstance(def_outs[0].get("defaultCameraConfigValues"), dict):
            self.defaultValues = {int(k): v for k, v in
                                  def_outs[0]["defaultCameraConfigValues"].items()}
        if result == 1:
            self.statusChanged.emit("Default Camera Config values set successfully")
            status = 1
        else:
            self.statusChanged.emit("Set Default Camera Config values failed")
            status = 0
        return status

    def getWhiteBalanceSettings(self) -> tuple[int, str]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, ""
        result, outs = sdk_result(self.shelfVistaOnvif.getWhiteBalance("", self.defaultWbValue))
        whiteBalance = out_value(outs, 0, "")
        # defaultWbValue is an in/out std::string& in C++: always written back.
        self.defaultWbValue = out_value(outs, 1, self.defaultWbValue)
        if result == 1:
            return 1, whiteBalance
        _log.debug("getWhiteBalanceSettings failed")
        return 0, whiteBalance

    def getRecordingStatusSettings(self) -> tuple[int, str]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, ""
        result, outs = sdk_result(self.shelfVistaOnvif.getRecordingStatus("", ""))
        recordingStatus = out_value(outs, 0, "")
        if result == 1:
            return 1, recordingStatus
        return 0, recordingStatus

    def setWhiteBalanceSettings(self, whiteBalance: str) -> int:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        result, _ = sdk_result(self.shelfVistaOnvif.setWhiteBalance(whiteBalance))
        if result == 1:
            self.statusChanged.emit("White balance updated successfully")
            return 1
        self.statusChanged.emit("White balance update failed")
        return 0

    def setPan(self, pan: int) -> tuple[int, str]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, "Onvif not initialized"
        result, outs = sdk_result(self.shelfVistaOnvif.setPan(int(pan), ""))
        outMessage = out_value(outs, 0, "")
        if result == 1:
            self.statusChanged.emit("Pan property set successfully")
            return 1, outMessage
        self.statusChanged.emit("Pan property set failed")
        return 0, outMessage

    def setTilt(self, tilt: int) -> tuple[int, str]:
        if self.shelfVistaOnvif is None:
            _log.debug("onvif not initialized")
            return 0, "Onvif not initialized"
        result, outs = sdk_result(self.shelfVistaOnvif.setTilt(int(tilt), ""))
        outMessage = out_value(outs, 0, "")
        if result == 1:
            self.statusChanged.emit("Tilt property set successfully")
            return 1, outMessage
        self.statusChanged.emit("Tilt property set failed")
        return 0, outMessage
