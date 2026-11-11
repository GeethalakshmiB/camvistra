"""Routecam (Ethernet) ONVIF controller.

Port of CamVistra/Controller/include/RoutecamOnvifController.h and
CamVistra/Controller/src/RoutecamOnvifController.cpp.
QML context property: ``routecamOnvifController``.

Threading (same as C++):
  * the model is moved to a dedicated ``RoutecamOnvifWorker`` QThread;
  * every Q_INVOKABLE except ``loadRoutecamControls`` runs its model call on
    that thread and *blocks* the caller until it finishes (C++
    ``invokeModelBlocking`` / Qt::BlockingQueuedConnection). Here the job is
    posted with a queued signal and the caller waits on a
    ``threading.Event`` (GIL released while waiting);
  * ``loadRoutecamControls`` posts the whole 27-request load sequence to the
    worker without blocking; progress/finished signals are emitted from the
    worker thread and reach QML via queued (auto) connections;
  * the model's signals are forwarded with Qt.QueuedConnection.
Call :meth:`shutdown` (also hooked to ``QCoreApplication.aboutToQuit``) to
move the model back and stop the thread - the C++ destructor's work.

Diagnostics: every diagnostics call (session start/end, control-change
reports) is commented out in the C++ controller, so none is made here.
"""

from __future__ import annotations

import logging
import re
import threading

from PyQt5 import sip
from PyQt5.QtCore import (QCoreApplication, QJsonDocument, QJsonParseError, QObject, Qt, QThread,
                          pyqtSignal, pyqtSlot)

from camvistra import tslog
from camvistra.controllers.wifi_onvif_controller import make_diagnostics_adapter, read_json_document
from camvistra.models.routecam_onvif_model import (IMAGE_PROPERTY, IMAGE_PROPERTY_COMPRESSION_SIZE,
                                                   NETWORK_INTERFACE_CHAR_SIZE, CameraProperty,
                                                   RoutecamOnvifModel)
from camvistra.models.wifi_onvif_model import c_str, qstr_to_int

_log = logging.getLogger(__name__)

CP = CameraProperty

K_PROPERTY_MAP = {
    "Brightness": CP.PropertyBrightness,
    "Saturation": CP.PropertySaturation,
    "Contrast": CP.PropertyContrast,
    "Sharpness": CP.PropertySharpness,
    "ExposureAuto": CP.PropertyExposureAuto,
    "ExposureTime": CP.PropertyExposureTime,
    "AntiFlicker": CP.PropertyAntiFlicker,
    "MaxExposureTime": CP.PropertyMaxExposureTime,
    "MinExposureTime": CP.PropertyMinExposureTime,
    "Gain": CP.PropertyGain,
    "WhiteBalanceAuto": CP.PropertyWhiteBalanceAuto,
    "WhiteBalanceYrGain": CP.PropertyWhitBalanceYrGain,
    "WhiteBalanceYbGain": CP.PropertyWhitBalanceYbGain,
    "WDR": CP.PropertyWDR,
    "BackLightCompensation": CP.PropertyBackLightCompensation,
}

K_PROPERTY_TO_UI_ID = {
    CP.PropertyBrightness: "brightness_s",
    CP.PropertySaturation: "saturation",
    CP.PropertyContrast: "contrast_s",
    CP.PropertySharpness: "sharpness_s",
    CP.PropertyExposureAuto: "exposureMode",
    CP.PropertyAntiFlicker: "antiFlicker",
    CP.PropertyExposureTime: "exposureTime",
    CP.PropertyMaxExposureTime: "max_exposure_s",
    CP.PropertyMinExposureTime: "min_exposure_s",
    CP.PropertyGain: "gain_s",
    CP.PropertyWhiteBalanceAuto: "wbMode",
    CP.PropertyWhitBalanceYbGain: "bGain",
    CP.PropertyWhitBalanceYrGain: "rGain",
    CP.PropertyWDR: "hdrMode_d",
    CP.PropertyBackLightCompensation: "backlightCompensation_d",
}

LOAD_TOTAL_REQUESTS = 27


class _Job:
    """A callable executed on the worker thread; the caller may wait on it."""

    __slots__ = ("fn", "result", "error", "done")

    def __init__(self, fn):
        self.fn = fn
        self.result = None
        self.error: BaseException | None = None
        self.done = threading.Event()

    def run(self) -> None:
        try:
            self.result = self.fn()
        except BaseException as exc:  # re-raised in the waiting caller
            self.error = exc
        finally:
            self.done.set()


class _ModelInvoker(QObject):
    """Posts :class:`_Job` objects to the model's thread (queued connection)."""

    post = pyqtSignal(object)


def _same_thread(a: QThread, b: QThread) -> bool:
    return sip.unwrapinstance(a) == sip.unwrapinstance(b)


class RoutecamOnvifController(QObject):
    routecamOnvifInitialized = pyqtSignal()
    jsonArrayRead = pyqtSignal("QVariantList", arguments=['jsonArray'])
    cameraControlProperty = pyqtSignal("QVariantList", arguments=['propList'])
    qualityControlProperty = pyqtSignal("QVariantList", arguments=['propList'])
    networkInterfaceDetails = pyqtSignal("QVariantList", arguments=['netInterfaceDetailsList'])
    ntpIPAddress = pyqtSignal(str, arguments=['ntpIp'])
    statusChanged = pyqtSignal(str, arguments=['status'])
    firmwareVersion = pyqtSignal(str, arguments=['firmwareVersion'])
    imagePropertiesMapChanged = pyqtSignal("QVariantMap", arguments=['propertiesMap'])
    currentImagePropertyChanged = pyqtSignal(str, str, str, arguments=['format', 'resolution', 'fps'])
    defaultUiValues = pyqtSignal("QVariantMap", arguments=['values'])
    deviceInformationReady = pyqtSignal("QVariantMap", arguments=['deviceInfo'])
    routecamControlUnavailable = pyqtSignal(str, int, arguments=['groupId', 'controlId'])
    routecamLoadingChanged = pyqtSignal(bool, arguments=['loading'])
    routecamLoadingProgress = pyqtSignal(int, int, arguments=['completed', 'total'])
    routecamLoadingFinished = pyqtSignal(bool, arguments=['success'])
    # Diagnostics: one Routecam connection at a time, keyed by a fixed string.
    kDiagnosticsSessionKey = "Routecam"

    def __init__(self, model: RoutecamOnvifModel | None = None,
                 parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.routecamOnvifModel = model if model is not None else RoutecamOnvifModel()
        m = self.routecamOnvifModel
        q = Qt.QueuedConnection
        m.routecamOnvifInitialized.connect(self.routecamOnvifInitialized, q)
        m.cameraControlProperty.connect(self.cameraControlProperty, q)
        m.qualityControlProperty.connect(self.qualityControlProperty, q)
        m.networkInterfaceDetails.connect(self.networkInterfaceDetails, q)
        m.ntpIPAddress.connect(self.ntpIPAddress, q)
        m.imagePropertiesMapChanged.connect(self.imagePropertiesMapChanged, q)
        m.currentImagePropertyChanged.connect(self.currentImagePropertyChanged, q)
        m.statusChanged.connect(self.statusChanged, q)

        self._invoker = _ModelInvoker()
        self._invoker.post.connect(m._runJob, Qt.QueuedConnection)

        self._loading_lock = threading.Lock()
        self._routecamLoading = False
        self.deviceName = ""

        self._diagnosticsControlAdapter = None
        self._diagnosticsAdapterCreated = False
        self._shutdown_done = False

        self.routecamWorkerThread = QThread()
        self.routecamWorkerThread.setObjectName("RoutecamOnvifWorker")
        m.moveToThread(self.routecamWorkerThread)
        self.routecamWorkerThread.start()

        app = QCoreApplication.instance()
        if app is not None:
            app.aboutToQuit.connect(self.shutdown)

    # ------------------------------------------------------------------
    # Worker-thread plumbing
    # ------------------------------------------------------------------

    def _invoke_model_blocking(self, fn):
        """Run ``fn`` on the model's thread and wait for its result."""
        if _same_thread(QThread.currentThread(), self.routecamOnvifModel.thread()):
            return fn()
        job = _Job(fn)
        self._invoker.post.emit(job)
        job.done.wait()
        if job.error is not None:
            raise job.error
        return job.result

    def shutdown(self) -> None:
        """C++ ~RoutecamOnvifController: stop the worker (diagnostics endSession is commented out)."""
        if self._shutdown_done:
            return
        self._shutdown_done = True
        # end_diagnostics_session(self.kDiagnosticsSessionKey)
        if self.routecamWorkerThread.isRunning():
            app = QCoreApplication.instance()
            if app is not None:
                app_thread = app.thread()
                self._invoke_model_blocking(
                    lambda: self.routecamOnvifModel.moveToThread(app_thread))
            self.routecamWorkerThread.quit()
            self.routecamWorkerThread.wait()

    @property
    def diagnosticsControlAdapter(self):
        if not self._diagnosticsAdapterCreated:
            self._diagnosticsAdapterCreated = True
            self._diagnosticsControlAdapter = make_diagnostics_adapter("RoutecamUvcControlAdapter")
        return self._diagnosticsControlAdapter

    # ------------------------------------------------------------------
    @pyqtSlot(result=bool)
    def readJsonArrayFile(self) -> bool:
        opened, doc, err = read_json_document(":/View/JSON/ethernetProperty.json")
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
    def initializeRoutecamOnvif(self, ipAddress: str) -> int:
        result = self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.initializeRoutecamOnvif(ipAddress))
        # Diagnostics session restart is commented out in C++:
        # if result == 1:
        #     restart_diagnostics_session(self.kDiagnosticsSessionKey, ipAddress,
        #                                 self.diagnosticsControlAdapter)
        return result

    @pyqtSlot(str, result=bool)
    def loadRoutecamControls(self, ipAddress: str) -> bool:
        with self._loading_lock:
            if self._routecamLoading:
                return False
            self._routecamLoading = True

        self.routecamLoadingChanged.emit(True)
        # C++ QMetaObject::invokeMethod(..., Qt::QueuedConnection) returns
        # false only when it cannot queue; a stopped worker is the Python
        # equivalent (the job would never run).
        queued = self.routecamWorkerThread.isRunning()
        if queued:
            self._invoker.post.emit(_Job(lambda: self._load_sequence(ipAddress)))
        else:
            self._set_loading(False)
            self.routecamLoadingChanged.emit(False)
            self.routecamLoadingFinished.emit(False)
        return queued

    def _set_loading(self, value: bool) -> None:
        with self._loading_lock:
            self._routecamLoading = value

    def _load_sequence(self, ipAddress: str) -> None:
        """Runs on the worker thread (C++ lambda in loadRoutecamControls)."""
        model = self.routecamOnvifModel
        total = LOAD_TOTAL_REQUESTS
        completed = 0
        success = False
        try:
            success = model.initializeRoutecamOnvif(ipAddress) == 1
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)

            infoMap: dict = {}
            if success:
                result, info = model.getDeviceInfo()
                if result == 1:
                    infoMap["manufacturer"] = info["manufacturer"]
                    infoMap["firmwareVersion"] = info["firmwareVersion"]
                    infoMap["name"] = info["name"]
                    self.deviceName = info["firmwareVersion"]
                    self.firmwareVersion.emit("Firmware version:  " + info["firmwareVersion"])
            self.deviceInformationReady.emit(infoMap)
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)

            if success and model.getImageProperty() != 1:
                self.routecamControlUnavailable.emit("vidProperties", 0)
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)

            if success and model.getCurrentImageProperty() != 1:
                self.routecamControlUnavailable.emit("vidProperties", 0)
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)

            for controlId in range(15):
                if success and model.getCameraControlProperty(controlId) != 1:
                    self.routecamControlUnavailable.emit("cameraSettings", controlId)
                completed += 1
                self.routecamLoadingProgress.emit(completed, total)

            for settingId in range(6):
                if success and model.getQualitySetting(settingId) != 1:
                    self.routecamControlUnavailable.emit("qualitySettings", settingId)
                completed += 1
                self.routecamLoadingProgress.emit(completed, total)

            if success and model.getNetworkInterface()[0] != 1:
                self.routecamControlUnavailable.emit("networkSettings", 0)
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)

            if success:
                model.getNTP()
            completed += 1
            self.routecamLoadingProgress.emit(completed, total)
        except Exception as exc:  # port safeguard: never leave "loading" stuck
            tslog.log_critical(0, f"Routecam control loading raised {exc!r}")
            success = False
        self._set_loading(False)
        self.routecamLoadingChanged.emit(False)
        self.routecamLoadingFinished.emit(success)

    @pyqtSlot(result=int)
    def getImageProperty(self) -> int:
        if self._invoke_model_blocking(self.routecamOnvifModel.getImageProperty) == 1:
            return 1
        _log.debug("Error: Failed to retrieve Image property.")
        return 0

    @pyqtSlot(result=int)
    def getCurrentImageProperty(self) -> int:
        if self._invoke_model_blocking(self.routecamOnvifModel.getCurrentImageProperty) == 1:
            return 1
        _log.debug("Error: Failed to retrieve CurrentImage property.")
        return 0

    @pyqtSlot(int, result=int)
    def getCameraControlProperty(self, controlId: int) -> int:
        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.getCameraControlProperty(controlId))

    @pyqtSlot(int, result=int)
    def getQualitySetting(self, settingsId: int) -> int:
        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.getQualitySetting(settingsId))

    @pyqtSlot(result=int)
    def getDeviceInfo(self) -> int:
        return self._invoke_model_blocking(lambda: self.routecamOnvifModel.getDeviceInfo()[0])

    @pyqtSlot(result=int)
    def getNTP(self) -> int:
        return self._invoke_model_blocking(lambda: self.routecamOnvifModel.getNTP()[0])

    @pyqtSlot(result=int)
    def getNetworkInterface(self) -> int:
        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.getNetworkInterface()[0])

    @pyqtSlot(str, result="QVariantMap")
    def getStreamUrl(self, deviceIP: str) -> dict:
        infoMap: dict = {}
        result, srcUrl = self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.getStreamUrl(deviceIP))
        if result == 1:
            infoMap["deviceIP"] = deviceIP
            infoMap["srcUrl"] = srcUrl
        else:
            _log.debug("Error: Failed to retrieve GetStreamUrl.")
        return infoMap

    @pyqtSlot(result=int)
    def getConfigProfile(self) -> int:
        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.getConfigProfile("H264")[0])

    @pyqtSlot(str, int, result=int)
    def setCameraControlProperty(self, controlId: str, value: int) -> int:
        result = self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.setCameraControlProperty(controlId, value))
        # if result == 1:
        #     adapter_report(self.diagnosticsControlAdapter, "reportControlChange", controlId, value)
        return result

    @pyqtSlot(str, int, result=int)
    def setQualitySettings(self, settingsId: str, value: int) -> int:
        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.setQualitySettings(settingsId, value))

    @pyqtSlot(result=int)
    def setQualityParameters(self) -> int:
        return self._invoke_model_blocking(self.routecamOnvifModel.setQualityParameters)

    @pyqtSlot(str, result=int)
    def setNTP(self, ipAddress: str) -> int:
        return self._invoke_model_blocking(lambda: self.routecamOnvifModel.setNTP(ipAddress))

    @pyqtSlot(str, str, str, str, result=int)
    def setCurrentImageProperty(self, format: str, resolution: str, fps: str,  # noqa: A002
                                codecProf: str) -> int:
        imageProperty = dict(IMAGE_PROPERTY)
        imageProperty["Compression"] = c_str(format, IMAGE_PROPERTY_COMPRESSION_SIZE)

        # Parse resolution (e.g. "3840x2160")
        resParts = [p for p in resolution.split("x") if p]
        if len(resParts) == 2:
            imageProperty["width"] = qstr_to_int(resParts[0])
            imageProperty["height"] = qstr_to_int(resParts[1])
        else:
            _log.warning("Invalid resolution format: %s", resolution)
            imageProperty["width"] = 1920
            imageProperty["height"] = 1080

        # Parse FPS (e.g. "30fps" -> 30)
        imageProperty["fps"] = qstr_to_int(re.sub("fps", "", fps, flags=re.IGNORECASE))

        return self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.setCurrentImageProperty(imageProperty, codecProf))

    @pyqtSlot(str, str, str, str, result=int)
    def setNetworkInterfaceDetails(self, isDHCP: str, networkIP: str, subnetMask: str,
                                   gateway: str) -> int:
        dhcp = isDHCP.upper() in ("ON", "TRUE")
        netInterface = {"DHCP": dhcp, "ipAddress": "", "subnetMask": "", "gateway": ""}
        if not dhcp:
            # Static mode requires address values; DHCP leaves them empty.
            netInterface["ipAddress"] = c_str(networkIP, NETWORK_INTERFACE_CHAR_SIZE)
            netInterface["subnetMask"] = c_str(subnetMask, NETWORK_INTERFACE_CHAR_SIZE)
            netInterface["gateway"] = c_str(gateway, NETWORK_INTERFACE_CHAR_SIZE)
        return self._invoke_model_blocking(lambda: self.routecamOnvifModel.setNetwork(netInterface))

    @pyqtSlot(result="QVariantMap")
    def getDeviceInformationMap(self) -> dict:
        infoMap: dict = {}
        result, info = self._invoke_model_blocking(self.routecamOnvifModel.getDeviceInfo)
        if result == 1:
            infoMap["manufacturer"] = info["manufacturer"]
            infoMap["firmwareVersion"] = info["firmwareVersion"]
            self.firmwareVersion.emit("Firmware version:  " + info["firmwareVersion"])
            infoMap["name"] = info["name"]
            self.deviceName = info["firmwareVersion"]
        else:
            _log.debug("Error: Failed to retrieve device information.")
        return infoMap

    @pyqtSlot(result=int)
    def setDefaultValues(self) -> int:
        deviceName = self.deviceName
        if deviceName.startswith("12.0"):
            path = ":/View/JSON/Routecam_cu514.json"
        elif deviceName.startswith("9.0"):
            path = ":/View/JSON/Routecam_cu86Default.json"
        elif deviceName.startswith("15.0"):
            path = ":/View/JSON/Routecam_cu22Default.json"
        else:
            return 0

        from PyQt5.QtCore import QFile, QIODevice
        f = QFile(path)
        if not f.open(QIODevice.ReadOnly):
            _log.debug("Failed to open file: %s", f.errorString())
            return -1
        data = f.readAll()
        f.close()

        error = QJsonParseError()
        doc = QJsonDocument.fromJson(data, error)
        if error.error != QJsonParseError.NoError or not doc.isObject():
            _log.debug("JSON parse error: %s", error.errorString())
            return -1

        # Read JSON -> enum map (QJsonObject iterates keys in sorted order)
        defaults: dict[int, int] = {}
        obj = doc.object()
        for key in sorted(obj.keys()):
            value = obj[key]
            if key not in K_PROPERTY_MAP:
                _log.debug("Unknown camera property: %s", key)
                continue
            if not value.isDouble():
                _log.debug("Invalid value type for: %s", key)
                continue
            defaults[K_PROPERTY_MAP[key]] = value.toInt()

        # Convert enum -> UI IDs and emit
        uiValues: dict[str, object] = {}
        for prop in sorted(defaults):
            value = defaults[prop]
            if prop not in K_PROPERTY_TO_UI_ID:
                continue
            uiId = K_PROPERTY_TO_UI_ID[prop]
            if prop in (CP.PropertyExposureAuto, CP.PropertyWhiteBalanceAuto):
                uiValues[uiId] = "AUTO" if value == 1 else "MANUAL"
            elif prop in (CP.PropertyWDR, CP.PropertyBackLightCompensation):
                uiValues[uiId] = "ON" if value == 1 else "OFF"
            else:
                uiValues[uiId] = value

        # Emit ONCE for UI
        self.defaultUiValues.emit(dict(sorted(uiValues.items())))

        # Apply defaults to camera
        payload = {"defaultCameraPropertyValues": defaults}
        return self._invoke_model_blocking(lambda: self.routecamOnvifModel.setDefaultValues(payload))

    @pyqtSlot(str, result=bool)
    def checkIPConnection(self, ipAddress: str) -> bool:
        return bool(self._invoke_model_blocking(
            lambda: self.routecamOnvifModel.checkIPConnection(ipAddress)))
