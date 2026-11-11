// Core bindings: Result codes, the Logger SDK and the DeviceEnumeration SDK.
#include "common.h"

#include "ILogger.h"
#include "IDeviceEnumerator.h"
// The *_Exports.h headers define the export macros and include the interfaces
// (IAudioDevices.h, INetworkDevices.h, IUsbDevices.h).
#include "AudioDeviceEnumeration_Exports.h"
#include "NetworkDeviceEnumeration_Exports.h"
#include "UsbDeviceEnumeration_Exports.h"

#include <memory>
#include <mutex>

namespace {

// ---- Logger callback trampoline -------------------------------------------
// logSDK stores its callback in a plain std::function that SDK threads invoke
// without synchronisation, so replacing it while another thread logs corrupts
// the heap. We therefore install ONE native trampoline at import time and
// never touch the SDK callback again; Python targets are swapped under our
// own mutex. The trampoline only enters Python while a target is set, so
// clearing it at exit makes late SDK log calls safe.
std::mutex g_logMtx;
std::shared_ptr<py::function> g_logTarget;  // guarded by g_logMtx

void log_trampoline(int priority, const std::string& message) {
    std::shared_ptr<py::function> target;
    {
        std::lock_guard<std::mutex> lock(g_logMtx);
        target = g_logTarget;
    }
    if (!target || !Py_IsInitialized()) return;
    py::gil_scoped_acquire gil;
    try {
        (*target)(priority, message);
    } catch (py::error_already_set& e) {
        e.restore();
        PyErr_WriteUnraisable(py::str("Logger callback").ptr());
    }
    target.reset();  // may drop the last reference: do it with the GIL held
}

void set_log_target(py::object fn) {
    std::shared_ptr<py::function> next;
    if (!fn.is_none()) next = std::make_shared<py::function>(fn.cast<py::function>());
    std::shared_ptr<py::function> previous;
    {
        std::lock_guard<std::mutex> lock(g_logMtx);
        previous = std::move(g_logTarget);
        g_logTarget = std::move(next);
    }
    // `previous` is released here, with the GIL held by our caller.
}

// Python-facing Logger. logSDK::createLoggerInstance() hands out the
// process-wide logger, which is never deleted (ILogger has no virtual
// destructor), so this only keeps a non-owning pointer.
struct LoggerHandle {
    logSDK::ILogger* logger = logSDK::createLoggerInstance();
};

// Python-facing DeviceManager, built on the public enumeration interfaces.
// enumerateAllDevices() goes through IDeviceEnumerator; the per-type
// enumerators are created on first use, as only tests call them.
struct DeviceEnumerators {
    DeviceManager::IDeviceEnumeratorPtr all = DeviceManager::createDeviceEnumerator();
    std::unique_ptr<NetworkDeviceEnumeration::INetworkDevices> network;
    std::unique_ptr<UsbDeviceEnumeration::IUsbDevices> usb;
    std::unique_ptr<AudioDeviceEnumeration::IAudioDevices> audio;
};

// Runs one enumeration without holding the GIL and returns
// (result, [device dicts], count). A missing enumerator reports Failed.
template <typename Enumerator>
py::tuple enumerate_devices(Enumerator* enumerator) {
    std::list<DeviceDetails> devices;
    int count = 0;
    Result r = Failed;
    {
        py::gil_scoped_release nogil;
        if (enumerator != nullptr) {
            r = enumerator->getAvailableDevices(devices, &count);
        }
    }
    return py::make_tuple(static_cast<int>(r), ts::to_py(devices), count);
}

}  // namespace

void bind_core(py::module_& m) {
    // Result codes (Logger/Common_Enums.h) as plain integer constants: the
    // application compares them with ints (e.g. "== 1") just like the C++ code.
    py::module_ result = m.def_submodule("Result", "SDK result codes (Common_Enums.h)");
#define TS_RESULT(name) result.attr(#name) = static_cast<int>(name)
    TS_RESULT(Ok); TS_RESULT(Failed); TS_RESULT(InvalidDeviceUrl); TS_RESULT(CameraNotOpened);
    TS_RESULT(CameraAlreadyOpened); TS_RESULT(NoDeviceConnected); TS_RESULT(InvalidValue);
    TS_RESULT(TimeoutError); TS_RESULT(DeviceNotInitialized); TS_RESULT(NotInitialized);
    TS_RESULT(InvalidStreamInfo); TS_RESULT(InvalidDecoder); TS_RESULT(InvalidCodec);
    TS_RESULT(NullValue); TS_RESULT(AlreadyInitialized); TS_RESULT(Exception);
    TS_RESULT(InvalidFilePath); TS_RESULT(NotFound); TS_RESULT(NotDeInitialized);
    TS_RESULT(InvalidNode); TS_RESULT(InvalidDeviceIndex); TS_RESULT(SysCallFail);
    TS_RESULT(DeviceNotCapable); TS_RESULT(CallBackFailed); TS_RESULT(PropertyValueGetFailed);
    TS_RESULT(PropertyValueSetFailed); TS_RESULT(InvalidFrameType); TS_RESULT(NoStreaming);
    TS_RESULT(AlreadyStreaming); TS_RESULT(HidWriteFail); TS_RESULT(HidReadFail);
    TS_RESULT(Others); TS_RESULT(ErrorPAConnectFailed); TS_RESULT(ErrorPAEnumerationFailed);
#undef TS_RESULT

    m.attr("DEBUG_INFO") = DEBUG_INFO;
    m.attr("DEBUG_VERBOSE") = DEBUG_VERBOSE;
    m.attr("DEBUG_CRITICAL") = DEBUG_CRITICAL;

    // The SDK logger is a process-wide singleton, so every Python Logger
    // instance shares one log file and one callback.
    py::class_<LoggerHandle>(m, "Logger")
        .def(py::init<>())
        .def("writeLog",
             [](LoggerHandle& self, int priority, const std::string& message) {
                 Result r = Failed;
                 {
                     py::gil_scoped_release nogil;
                     if (self.logger != nullptr) r = self.logger->writeLog(priority, message);
                 }
                 return static_cast<int>(r);
             },
             py::arg("priority"), py::arg("message"))
        .def("setLogCallback",
             [](LoggerHandle&, py::object cb) {
                 set_log_target(std::move(cb));
                 return static_cast<int>(Ok);
             },
             py::arg("callback"),
             "Register callback(priority, message) (None clears it). It may be "
             "invoked from SDK threads; the GIL is acquired automatically.")
        .def("clearLogCallback",
             [](LoggerHandle&) {
                 // Must run before interpreter shutdown: the logger is a
                 // process-wide singleton that outlives Python.
                 set_log_target(py::none());
                 return static_cast<int>(Ok);
             });

    // Install the trampoline once; the SDK callback is never replaced again.
    if (logSDK::ILogger* installer = logSDK::createLoggerInstance()) {
        installer->setLogCallback(&log_trampoline);
    }

    py::class_<DeviceEnumerators>(m, "DeviceManager")
        .def(py::init<>(), py::call_guard<py::gil_scoped_release>())
        .def("enumerateAllDevices",
             [](DeviceEnumerators& self) {
                 return enumerate_devices(self.all.get());
             })
        .def("enumerateNetworkDevices",
             [](DeviceEnumerators& self) {
                 if (!self.network) self.network = NetworkDeviceEnumeration::createNetworkDeviceEnumerator();
                 return enumerate_devices(self.network.get());
             })
        .def("enumerateUsbDevices",
             [](DeviceEnumerators& self) {
                 if (!self.usb) self.usb = UsbDeviceEnumeration::createUsbDeviceEnumerator();
                 return enumerate_devices(self.usb.get());
             })
        .def("enumerateAudioDevices",
             [](DeviceEnumerators& self) {
                 if (!self.audio) self.audio = AudioDeviceEnumeration::createAudioDeviceEnumerator();
                 return enumerate_devices(self.audio.get());
             });
}
