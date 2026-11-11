// Optional native crash reporter (Windows): prints the faulting module/offset
// and a captured back-trace as module+offset pairs to stderr before the
// process dies. Enabled by camvistra.native when CAMVISTRA_CRASH_TRACE=1.
// Intended for field diagnosis of crashes inside the SDKs or Qt, where
// Python's faulthandler only shows the Python frames.
#include "common.h"

#ifdef _WIN32
#include <windows.h>
#include <cstdio>

namespace {

void describe(void* addr, char* out, size_t n) {
    HMODULE mod = nullptr;
    char path[MAX_PATH] = "?";
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           static_cast<LPCSTR>(addr), &mod) && mod) {
        GetModuleFileNameA(mod, path, MAX_PATH);
        const char* base = strrchr(path, '\\');
        _snprintf_s(out, n, _TRUNCATE, "%s+0x%llx", base ? base + 1 : path,
                    static_cast<unsigned long long>(reinterpret_cast<char*>(addr) - reinterpret_cast<char*>(mod)));
    } else {
        _snprintf_s(out, n, _TRUNCATE, "%p", addr);
    }
}

LONG CALLBACK handler(EXCEPTION_POINTERS* info) {
    const DWORD code = info->ExceptionRecord->ExceptionCode;
    if (code != EXCEPTION_ACCESS_VIOLATION && code != 0xC0000374 && code != EXCEPTION_STACK_OVERFLOW &&
        code != EXCEPTION_ILLEGAL_INSTRUCTION && code != EXCEPTION_INT_DIVIDE_BY_ZERO) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    char where[512];
    describe(info->ExceptionRecord->ExceptionAddress, where, sizeof(where));
    fprintf(stderr, "\n[camvistra crash] code=0x%08lx thread=%lu at %s\n", code, GetCurrentThreadId(), where);
    void* frames[48];
    const USHORT n = CaptureStackBackTrace(0, 48, frames, nullptr);
    for (USHORT i = 0; i < n; ++i) {
        describe(frames[i], where, sizeof(where));
        fprintf(stderr, "  #%02u %s\n", i, where);
    }
    fflush(stderr);
    return EXCEPTION_CONTINUE_SEARCH;
}

}  // namespace
#endif

void bind_crash_trace(py::module_& m) {
    m.def("install_crash_trace", []() {
#ifdef _WIN32
        static PVOID h = AddVectoredExceptionHandler(1, handler);
        return h != nullptr;
#else
        return false;
#endif
    });
}
