// Shared helpers for the camvistra native (pybind11) module.
//
// ts::to_py / ts::from_py convert SDK values to/from Python objects:
//   arithmetic -> int/float/bool, enums -> int, std::string / char[N] -> str,
//   other arrays and std::list/std::vector -> list, std::map -> dict,
//   SDK structs -> dict.
//
// Conversion is dispatched through the class template ts::Conv<T>. SDK
// structs get explicit specialisations (hand-written below for
// Common_Structs.h, generated for the camera/ONVIF headers). Class template
// specialisations are looked up at instantiation time, so containers of
// structs convert correctly regardless of declaration order - something
// plain overloads cannot do for types that live outside namespace ts.
#pragma once

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#endif

#include <pybind11/pybind11.h>
#include <pybind11/functional.h>
#include <pybind11/stl.h>

#include <algorithm>
#include <array>
#include <cstring>
#include <list>
#include <map>
#include <string>
#include <type_traits>
#include <vector>

#include "Logger.h"  // Result, Frame, ImageProperty, PropertyRange, DeviceDetails

namespace py = pybind11;

namespace ts {

// SDK strings are nominally UTF-8, but Windows device names come from ANSI
// APIs (e.g. "(R)" as 0xAE). Fall back to the active code page there.
inline py::str decode_utf8(const char* data, size_t len) {
    py::bytes raw(data, len);
    try {
        return py::str(raw.attr("decode")("utf-8", "strict"));
    } catch (py::error_already_set&) {
#ifdef _WIN32
        return py::str(raw.attr("decode")("mbcs", "replace"));
#else
        return py::str(raw.attr("decode")("utf-8", "replace"));
#endif
    }
}

// Primary template: scalars, enums, std::string.
template <typename T, typename = void>
struct Conv {
    static py::object to(const T& v) {
        if constexpr (std::is_same_v<T, bool>) {
            return py::bool_(v);
        } else if constexpr (std::is_enum_v<T> || std::is_integral_v<T>) {
            return py::int_(static_cast<long long>(v));
        } else if constexpr (std::is_floating_point_v<T>) {
            return py::float_(static_cast<double>(v));
        } else if constexpr (std::is_same_v<T, std::string>) {
            return decode_utf8(v.data(), v.size());
        } else if constexpr (std::is_same_v<T, std::wstring>) {
            return py::cast(v);
        } else {
            static_assert(sizeof(T) == 0, "ts::Conv: no conversion for this SDK type");
        }
    }
    static void from(py::handle h, T& v) {
        if constexpr (std::is_same_v<T, bool>) {
            v = h.cast<bool>();
        } else if constexpr (std::is_enum_v<T> || std::is_integral_v<T>) {
            v = static_cast<T>(h.cast<long long>());
        } else if constexpr (std::is_floating_point_v<T>) {
            v = static_cast<T>(h.cast<double>());
        } else if constexpr (std::is_same_v<T, std::string> || std::is_same_v<T, std::wstring>) {
            v = h.cast<T>();
        } else {
            static_assert(sizeof(T) == 0, "ts::Conv: no conversion for this SDK type");
        }
    }
};

template <typename T>
inline py::object to_py(const T& v) { return Conv<T>::to(v); }
template <typename T>
inline void from_py(py::handle h, T& v) { Conv<T>::from(h, v); }

// Fixed-size arrays: char[N] <-> str, others <-> list.
template <typename T, size_t N>
struct Conv<T[N]> {
    static py::object to(const T (&a)[N]) {
        if constexpr (std::is_same_v<T, char>) {
            return decode_utf8(a, strnlen(a, N));
        } else {
            py::list out;
            for (size_t i = 0; i < N; ++i) out.append(to_py(a[i]));
            return std::move(out);
        }
    }
    static void from(py::handle h, T (&a)[N]) {
        if constexpr (std::is_same_v<T, char>) {
            const std::string s = h.cast<std::string>();
            std::memset(a, 0, N);
            std::memcpy(a, s.data(), (std::min)(s.size(), N - 1));
        } else {
            auto seq = py::reinterpret_borrow<py::sequence>(h);
            for (size_t i = 0; i < N && i < seq.size(); ++i) from_py(seq[i], a[i]);
        }
    }
};

template <typename T, size_t N>
struct Conv<std::array<T, N>> {
    static py::object to(const std::array<T, N>& a) {
        if constexpr (std::is_same_v<T, char>) {
            return decode_utf8(a.data(), strnlen(a.data(), N));
        } else {
            py::list out;
            for (const auto& e : a) out.append(to_py(e));
            return std::move(out);
        }
    }
    static void from(py::handle h, std::array<T, N>& a) {
        if constexpr (std::is_same_v<T, char>) {
            const std::string s = h.cast<std::string>();
            a.fill('\0');
            std::memcpy(a.data(), s.data(), (std::min)(s.size(), N - 1));
        } else {
            auto seq = py::reinterpret_borrow<py::sequence>(h);
            for (size_t i = 0; i < N && i < seq.size(); ++i) from_py(seq[i], a[i]);
        }
    }
};

template <typename T>
struct Conv<std::list<T>> {
    static py::object to(const std::list<T>& v) {
        py::list out;
        for (const auto& e : v) out.append(to_py(e));
        return std::move(out);
    }
    static void from(py::handle h, std::list<T>& v) {
        v.clear();
        for (auto item : h) { T e{}; from_py(item, e); v.push_back(std::move(e)); }
    }
};

template <typename T>
struct Conv<std::vector<T>> {
    static py::object to(const std::vector<T>& v) {
        py::list out;
        for (const auto& e : v) out.append(to_py(e));
        return std::move(out);
    }
    static void from(py::handle h, std::vector<T>& v) {
        v.clear();
        for (auto item : h) { T e{}; from_py(item, e); v.push_back(std::move(e)); }
    }
};

template <typename K, typename V>
struct Conv<std::map<K, V>> {
    static py::object to(const std::map<K, V>& v) {
        py::dict out;
        for (const auto& kv : v) out[to_py(kv.first)] = to_py(kv.second);
        return std::move(out);
    }
    static void from(py::handle h, std::map<K, V>& v) {
        v.clear();
        auto d = py::reinterpret_borrow<py::dict>(h);
        for (auto kv : d) {
            K k{}; V val{};
            from_py(kv.first, k);
            from_py(kv.second, val);
            v[k] = std::move(val);
        }
    }
};

// ---- Common_Structs.h ---------------------------------------------------

template <>
struct Conv<PropertyRange> {
    static py::object to(const PropertyRange& v) {
        py::dict d;
        d["id"] = v.id; d["min"] = v.min; d["max"] = v.max; d["cur"] = v.cur;
        d["step"] = v.step; d["defaultVal"] = v.defaultVal; d["automan"] = v.automan;
        return std::move(d);
    }
    static void from(py::handle h, PropertyRange& v) {
        auto d = py::reinterpret_borrow<py::dict>(h);
        if (d.contains("id")) from_py(d["id"], v.id);
        if (d.contains("min")) from_py(d["min"], v.min);
        if (d.contains("max")) from_py(d["max"], v.max);
        if (d.contains("cur")) from_py(d["cur"], v.cur);
        if (d.contains("step")) from_py(d["step"], v.step);
        if (d.contains("defaultVal")) from_py(d["defaultVal"], v.defaultVal);
        if (d.contains("automan")) from_py(d["automan"], v.automan);
    }
};

template <>
struct Conv<ImageProperty> {
    static py::object to(const ImageProperty& v) {
        py::dict d;
        d["Compression"] = to_py(v.Compression);
        d["width"] = v.width; d["height"] = v.height; d["fps"] = v.fps;
        d["isNV12Decoded"] = v.isNV12Decoded;
        return std::move(d);
    }
    static void from(py::handle h, ImageProperty& v) {
        auto d = py::reinterpret_borrow<py::dict>(h);
        if (d.contains("Compression")) from_py(d["Compression"], v.Compression);
        if (d.contains("width")) from_py(d["width"], v.width);
        if (d.contains("height")) from_py(d["height"], v.height);
        if (d.contains("fps")) from_py(d["fps"], v.fps);
        if (d.contains("isNV12Decoded")) from_py(d["isNV12Decoded"], v.isNV12Decoded);
    }
};

template <>
struct Conv<DeviceDetails> {
    static py::object to(const DeviceDetails& v) {
        py::dict d;
        d["deviceIndex"] = v.deviceIndex;
        d["DeviceName"] = to_py(v.DeviceName);
        d["DeviceIP"] = to_py(v.DeviceIP);
        d["type"] = to_py(v.type);
        d["alsaHwId"] = to_py(v.alsaHwId);
        d["vid"] = to_py(v.vid);
        d["pid"] = to_py(v.pid);
        d["devicePath"] = to_py(v.devicePath);
        d["serialNo"] = to_py(v.serialNo);
        return std::move(d);
    }
    static void from(py::handle h, DeviceDetails& v) {
        auto d = py::reinterpret_borrow<py::dict>(h);
        if (d.contains("deviceIndex")) from_py(d["deviceIndex"], v.deviceIndex);
        if (d.contains("DeviceName")) from_py(d["DeviceName"], v.DeviceName);
        if (d.contains("DeviceIP")) from_py(d["DeviceIP"], v.DeviceIP);
        if (d.contains("type")) from_py(d["type"], v.type);
        if (d.contains("vid")) from_py(d["vid"], v.vid);
        if (d.contains("pid")) from_py(d["pid"], v.pid);
        if (d.contains("devicePath")) from_py(d["devicePath"], v.devicePath);
        if (d.contains("serialNo")) from_py(d["serialNo"], v.serialNo);
    }
};

// Holder deleter for SDK classes whose destructor joins a thread that calls
// back into Python (e.g. DensiCAM's HID listener). Deleting with the GIL held
// would deadlock if that thread is waiting for the GIL to run the callback.
template <typename T>
struct NoGilDelete {
    void operator()(T* p) const {
        if (PyGILState_Check()) {
            py::gil_scoped_release nogil;
            delete p;
        } else {
            delete p;
        }
    }
};

}  // namespace ts

// Binding entry points (one per translation unit).
void bind_core(py::module_& m);
void bind_frames(py::module_& m);
void bind_frame_pump(py::module_& m);
void bind_imaging(py::module_& m);
void bind_crash_trace(py::module_& m);
void bind_generated(py::module_& m);
