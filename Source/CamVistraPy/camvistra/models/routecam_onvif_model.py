"""Routecam (Ethernet) ONVIF camera model.

Port of CamVistra/Model/include/RoutecamOnvifModel.h and
CamVistra/Model/src/RoutecamOnvifModel.cpp.

As in C++, :class:`RoutecamOnvifController` moves this QObject to its
``RoutecamOnvifWorker`` QThread and runs every model call there (blocking
network SDK calls stay off the GUI thread). The model's signals are therefore
emitted on the worker thread; the controller re-emits them through queued
connections. ``_runJob`` is the entry point the controller uses to execute a
callable on the worker thread (the Python stand-in for the C++
``QMetaObject::invokeMethod(&model, lambda, ...)``).

Getters that fill C++ out-parameters return tuples ``(result, out...)``.
"""

from __future__ import annotations

import logging
import sys

from PyQt5.QtCore import QObject, QProcess, pyqtSignal, pyqtSlot

from camvistra import tslog
from camvistra.models.wifi_onvif_model import c_div, out_struct, out_value, sdk_result

_log = logging.getLogger(__name__)

_UNSET = object()

# Result used when there is no SDK client (Result::Failed); every model
# method takes its SDK-failure branch in that case, as the C++ model does.
_NO_CLIENT = -1


# ---------------------------------------------------------------------------
# Routecam_Enums.h
# ---------------------------------------------------------------------------

class QualitySettings:
    GOPSIZE = 0
    VIDEO_BITRATE_MODE = 1
    BITRATE = 2
    I_FRAME_QP = 3
    MIN_QP = 4
    MAX_QP = 5


class CameraProperty:
    PropertyBrightness = 0
    PropertySaturation = 1
    PropertyContrast = 2
    PropertySharpness = 3
    PropertyExposureAuto = 4
    PropertyExposureTime = 5
    PropertyAntiFlicker = 6
    PropertyMaxExposureTime = 7
    PropertyMinExposureTime = 8
    PropertyGain = 9
    PropertyWhiteBalanceAuto = 10
    PropertyWhitBalanceYrGain = 11
    PropertyWhitBalanceYbGain = 12
    PropertyWDR = 13
    PropertyBackLightCompensation = 14


CP = CameraProperty
QS = QualitySettings

K_QUALITY_UI_TO_READABLE_NAME = {
    "gopSize_s": "GOP Size",
    "bitrate_s": "Bitrate",
    "iFrameQP_s": "I-Frame QP",
    "minQp_s": "Min QP",
    "maxQp_s": "Max QP",
    "rcType_d": "Rate Control Type",
}

K_QUALITY_UI_TO_PROPERTY = {
    "gopSize_s": (QS.GOPSIZE, lambda val: val),
    "bitrate_s": (QS.BITRATE, lambda val: c_div(val, 1000)),
    "iFrameQP_s": (QS.I_FRAME_QP, lambda val: val),
    "minQp_s": (QS.MIN_QP, lambda val: val),
    "maxQp_s": (QS.MAX_QP, lambda val: val),
    "rcType_d": (QS.VIDEO_BITRATE_MODE, lambda val: val),
}

K_CONTROL_ID_MAP = {
    "brightness_s": (CP.PropertyBrightness, "Brightness"),
    "saturation": (CP.PropertySaturation, "Saturation"),
    "contrast_s": (CP.PropertyContrast, "Contrast"),
    "sharpness_s": (CP.PropertySharpness, "Sharpness"),
    "exposureTime": (CP.PropertyExposureTime, "Exposure Time"),
    "min_exposure_s": (CP.PropertyMinExposureTime, "Min Exposure Time"),
    "max_exposure_s": (CP.PropertyMaxExposureTime, "Max Exposure Time"),
    "gain_s": (CP.PropertyGain, "Gain"),
    "bGain": (CP.PropertyWhitBalanceYbGain, "White Balance Yb Gain"),
    "rGain": (CP.PropertyWhitBalanceYrGain, "White Balance Yr Gain"),
    "wbMode": (CP.PropertyWhiteBalanceAuto, "White Balance Auto"),
    "hdrMode_d": (CP.PropertyWDR, "HDR"),
    "exposureMode": (CP.PropertyExposureAuto, "Exposure Auto"),
    "antiFlicker": (CP.PropertyAntiFlicker, "Anti Flicker"),
}

# controlId 0..14 -> CameraProperty (same numbering as the enum).
_CONTROL_IDS = {i: i for i in range(15)}
# settingId 0..5 -> QualitySettings (same numbering as the enum).
_SETTING_IDS = {i: i for i in range(6)}

# Zero-initialised SDK structs.
IMAGE_PROPERTY = dict(Compression="", width=0, height=0, fps=0, isNV12Decoded=False)
IMAGE_PROPERTY_COMPRESSION_SIZE = 8  # Logger/Common_Structs.h: char Compression[8]
PROPERTY_RANGE = dict(id=0, min=0, max=0, cur=0, step=0, defaultVal=0, automan=0)
QUALITY_SETTINGS_RANGE = dict(id=0, current=0, min=0, max=0)
DEVICE_INFO = dict.fromkeys(("manufacturer", "name", "firmwareVersion", "serialNumber",
                             "hardwareId"), "")
NETWORK_INTERFACE = dict(DHCP=False, ipAddress="", subnetMask="", gateway="")
NETWORK_INTERFACE_CHAR_SIZE = 32


def _fps_value(text: str) -> int:
    from camvistra.models.wifi_onvif_model import qstr_to_int
    return qstr_to_int(text[:-3]) if text.endswith("fps") else qstr_to_int(text)


def _default_client():
    from camvistra.native import sdk
    return sdk.getRoutecamOnvifInstance()


class RoutecamOnvifModel(QObject):
    routecamOnvifInitialized = pyqtSignal()
    cameraControlProperty = pyqtSignal("QVariantList")
    qualityControlProperty = pyqtSignal("QVariantList")
    networkInterfaceDetails = pyqtSignal("QVariantList")
    ntpIPAddress = pyqtSignal(str)
    statusChanged = pyqtSignal(str)

    imagePropertiesMapChanged = pyqtSignal("QVariantMap")
    currentImagePropertyChanged = pyqtSignal(str, str, str)

    def __init__(self, client=_UNSET, parent: QObject | None = None) -> None:
        super().__init__(parent)
        # ``client`` lets tests inject a fake IRoutecamOnvifClient.
        self.routecamOnvif = _default_client() if client is _UNSET else client
        self.imgProperties: list[dict] = []
        self.imagePropertiesMap: dict = {}
        self.currentFmt = ""
        self.currentProf = ""
        self.currentWidth = 0
        self.currentHeight = 0
        self.currentFps = 0

    # ------------------------------------------------------------------
    @pyqtSlot(object)
    def _runJob(self, job) -> None:
        """Execute a controller job on this object's (worker) thread."""
        job.run()

    # ------------------------------------------------------------------
    def initializeRoutecamOnvif(self, ipAddress: str) -> int:
        if self.routecamOnvif is None:
            return 0
        result, _ = sdk_result(self.routecamOnvif.initialize(ipAddress))
        if result == 1:
            self.routecamOnvifInitialized.emit()
            return 1
        return 0

    def getImageProperty(self) -> int:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        result, outs = sdk_result(self.routecamOnvif.GetImageProperty())
        if result != 1:
            _log.debug("GetImageProperty failed")
            return 0

        imageProperties = out_value(outs, 0, [])
        bitrateRanges = out_value(outs, 1, {})
        self.imgProperties = []
        # Nested map: format -> resolution -> {"fps": [...]}, plus per-format
        # "bitrateRange", "profiles" and "currentProfile".
        propertiesMap: dict = {}
        for raw in imageProperties:
            prop = out_struct((raw,), 0, IMAGE_PROPERTY)
            self.imgProperties.append(prop)
            fmt = prop["Compression"]
            resolution = f"{prop['width']}x{prop['height']}"
            fps = f"{prop['fps']}fps"
            formatMap = propertiesMap.setdefault(fmt, {})
            resolutionMap = formatMap.setdefault(resolution, {})
            fpsList = list(resolutionMap.get("fps", []))
            if fps not in fpsList:
                fpsList.append(fps)
            # Sort fps list numerically (descending order)
            fpsList.sort(key=_fps_value, reverse=True)
            resolutionMap["fps"] = fpsList

        for fmt in sorted(bitrateRanges):
            rng = out_struct((bitrateRanges[fmt],), 0, QUALITY_SETTINGS_RANGE)
            # QVariantMap::operator[] creates the format entry if missing.
            formatMap = propertiesMap.setdefault(fmt, {})
            formatMap["bitrateRange"] = {"min": rng["min"], "max": rng["max"]}

        # Now get profiles for each format (QMap::keys() -> sorted order).
        for fmt in sorted(propertiesMap):
            prof_result, prof_outs = sdk_result(
                self.routecamOnvif.GetConfigProfile([], "", fmt))
            if prof_result == 1:
                formatMap = propertiesMap[fmt]
                formatMap["profiles"] = [str(p) for p in out_value(prof_outs, 0, [])]
                formatMap["currentProfile"] = out_value(prof_outs, 1, "")

        self.imagePropertiesMap = propertiesMap
        self.imagePropertiesMapChanged.emit(propertiesMap)
        return 1

    def getCurrentImageProperty(self) -> int:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0
        result, outs = sdk_result(self.routecamOnvif.GetCurrentImageProperty())
        if result == 1:
            prop = out_struct(outs, 0, IMAGE_PROPERTY)
            self.currentFmt = prop["Compression"]
            self.currentWidth = prop["width"]
            self.currentFps = prop["fps"]
            self.currentHeight = prop["height"]
            self.currentImagePropertyChanged.emit(
                prop["Compression"], f"{prop['width']}x{prop['height']}", f"{prop['fps']}fps")
            return 1
        _log.debug("GetCurrentImageProperty failed")
        return 0

    def getCameraControlProperty(self, controlId: int) -> int:
        ret = -1
        outs: tuple = ()
        if controlId in _CONTROL_IDS and self.routecamOnvif is not None:
            ret, outs = sdk_result(
                self.routecamOnvif.GetCameraControlProperty(_CONTROL_IDS[controlId]))
        if ret == 1:
            rng = out_struct(outs, 0, PROPERTY_RANGE)
            self.cameraControlProperty.emit([rng["id"], rng["min"], rng["max"], rng["cur"],
                                             rng["step"], rng["automan"]])
        return ret

    def getQualitySetting(self, settingId: int) -> int:
        ret = -1
        outs: tuple = ()
        if settingId in _SETTING_IDS and self.routecamOnvif is not None:
            ret, outs = sdk_result(
                self.routecamOnvif.GetQualityContolProperty(_SETTING_IDS[settingId]))
        if ret == 1:
            rng = out_struct(outs, 0, QUALITY_SETTINGS_RANGE)
            self.qualityControlProperty.emit([rng["id"], rng["min"], rng["max"], rng["current"]])
        return ret

    def getDeviceInfo(self) -> tuple[int, dict]:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0, dict(DEVICE_INFO)
        result, outs = sdk_result(self.routecamOnvif.GetDeviceInformation())
        info = out_struct(outs, 0, DEVICE_INFO)
        if result == 1:
            return 1, info
        _log.debug("GetDeviceInformation failed")
        return 0, info

    def getNTP(self) -> tuple[int, str]:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0, ""
        result, outs = sdk_result(self.routecamOnvif.GetNTP(""))
        ntpIp = out_value(outs, 0, "")
        if result == 1:
            self.ntpIPAddress.emit(ntpIp)
            return 1, ntpIp
        _log.debug("GetNTP Failed failed")
        return 0, ntpIp

    def getNetworkInterface(self) -> tuple[int, dict]:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0, dict(NETWORK_INTERFACE)
        result, outs = sdk_result(self.routecamOnvif.GetNetworkInterfaceDetails())
        net = out_struct(outs, 0, NETWORK_INTERFACE)
        if result == 1:
            self.networkInterfaceDetails.emit([bool(net["DHCP"]), net["ipAddress"],
                                               net["subnetMask"], net["gateway"]])
            return 1, net
        _log.debug("GetNetworkInterface Failed ")
        return 0, net

    def getConfigProfile(self, currentFormat: str) -> tuple[int, list, str, str]:
        if self.routecamOnvif is None:
            _log.debug("onvif not initialized")
            return 0, [], "", currentFormat
        result, outs = sdk_result(self.routecamOnvif.GetConfigProfile([], "", currentFormat))
        allProfiles = list(out_value(outs, 0, []))
        currentProfile = out_value(outs, 1, "")
        currentFormat = out_value(outs, 2, currentFormat)
        if result == 1:
            self.currentProf = currentProfile
            return 1, allProfiles, currentProfile, currentFormat
        _log.debug("getConfigProfile Failed ")
        return 0, allProfiles, currentProfile, currentFormat

    def setCameraControlProperty(self, controlId: str, value: int) -> int:
        info = K_CONTROL_ID_MAP.get(controlId)
        if info is None:
            self.statusChanged.emit(f"Unknown control: {controlId}")
            return -1
        prop, displayName = info
        result = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
            self.routecamOnvif.SetCameraControlProperty(prop, str(int(value))))[0]
        if result == 1:
            status = f"{displayName} set successfully"
        else:
            status = f"Failed to set {displayName}"
        self.statusChanged.emit(status)
        return result

    def setQualitySettings(self, settingId: str, value: int) -> int:
        if self.routecamOnvif is None:
            return -1
        entry = K_QUALITY_UI_TO_PROPERTY.get(settingId)
        if entry is None:
            self.statusChanged.emit("Unknown quality setting")
            return -1
        prop, transform = entry
        transformedValue = transform(int(value))
        result, _ = sdk_result(self.routecamOnvif.SetQualityControlProperty(prop, transformedValue))
        readableName = K_QUALITY_UI_TO_READABLE_NAME.get(settingId, settingId)
        if result == 1:
            status = f"{readableName} set successfully"
        else:
            status = f"Failed to set {readableName}"
        self.statusChanged.emit(status)
        return result

    def setQualityParameters(self) -> int:
        result = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
            self.routecamOnvif.SetQualityParameters())[0]
        if result == 1:
            self.statusChanged.emit("Quality settings parameters has been set successfully")
        else:
            self.statusChanged.emit("Set Quality settings parameters has been failed")
        return result

    def setNTP(self, ipAddress: str) -> int:
        result = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
            self.routecamOnvif.SetNTP(ipAddress))[0]
        if result == 1:
            self.statusChanged.emit("NTP has been set successfully")
            return 1
        self.statusChanged.emit("Set NTP has been failed")
        return 0

    def setCurrentImageProperty(self, imageProperty: dict, configProfile: str) -> int:
        compression = imageProperty["Compression"]
        if (self.currentProf == configProfile and self.currentFmt == compression
                and self.currentHeight == imageProperty["height"]
                and self.currentWidth == imageProperty["width"]
                and self.currentFps == imageProperty["fps"]):
            self.statusChanged.emit("No changes were made to the video property values.")
            tslog.log_info(0, "No property changes requested")
            return 0
        formatChanged = self.currentFmt != compression
        if self.currentProf != configProfile or formatChanged:
            profileResult = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
                self.routecamOnvif.SetConfigProfile(configProfile))[0]
            # Result::Ok is 1; every error code is negative.
            if profileResult == 1:
                self.currentProf = configProfile
                tslog.log_info(profileResult, "Codec profile updated")
            else:
                tslog.log_critical(profileResult, "Codec profile update failed")
        result = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
            self.routecamOnvif.SetCurrentImageProperty(dict(imageProperty)))[0]
        if result == 1:
            self.currentFps = imageProperty["fps"]
            self.currentWidth = imageProperty["width"]
            self.currentHeight = imageProperty["height"]
            self.currentFmt = compression
            self.statusChanged.emit("Video property has been set successfully")
        else:
            self.statusChanged.emit("Set video property failed")
        return tslog.log_result(result, result == 1, "Video property update")

    def setNetwork(self, netInterface: dict) -> int:
        if self.routecamOnvif is None:
            self.statusChanged.emit("Set Network Interface details has been failed")
            return 0
        result, _ = sdk_result(self.routecamOnvif.SetNetworkInterfaceDetails(dict(netInterface)))
        # Result::Ok is 1; every error code is negative.
        if result == 1:
            self.statusChanged.emit("Network Interface details has been set successfully")
            return 1
        self.statusChanged.emit("Set Network Interface details has been failed")
        return 0

    def setDefaultValues(self, defaults: dict) -> int:
        res = _NO_CLIENT if self.routecamOnvif is None else sdk_result(
            self.routecamOnvif.setDefaultConfiguration(defaults))[0]
        if res == 1:
            self.statusChanged.emit("Default Values has been set successfully")
            return 1
        self.statusChanged.emit("Set Default Values failed")
        return -1

    def checkIPConnection(self, ipAddress: str) -> bool:
        ping = QProcess()
        if sys.platform == "win32":
            arguments = ["-n", "1", "-w", "1000", ipAddress]
        else:
            # Linux / macOS
            arguments = ["-c", "1", "-W", "1", ipAddress]
        ping.start("ping", arguments)

        if not ping.waitForFinished(3000):
            ping.kill()
            ping.waitForFinished(1000)
            self.statusChanged.emit("Ping timed out for IP: " + ipAddress)
            return False

        if ping.exitCode() != 0:
            self.statusChanged.emit("Ping failed for IP: " + ipAddress)
            return False
        return True

    def getStreamUrl(self, deviceIP: str) -> tuple[int, str]:
        if self.routecamOnvif is None:
            return 0, ""
        res, outs = sdk_result(self.routecamOnvif.GetStreamUri(deviceIP, ""))
        return (1 if res == 1 else 0), out_value(outs, 0, "")
