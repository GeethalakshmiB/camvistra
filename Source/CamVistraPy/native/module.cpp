// Entry point of the `camvistra._native` extension module.
#include "common.h"

PYBIND11_MODULE(_native, m) {
    m.doc() = "pybind11 bindings for the CamVistra C++ SDKs "
              "(CAMSDK, NetStreamSDK, ONVIF SDKs, DeviceEnumeration, Logger)";
    bind_core(m);
    bind_frames(m);
    bind_generated(m);
    bind_frame_pump(m);
    bind_imaging(m);
    bind_crash_trace(m);
}
