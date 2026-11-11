"""Loader for the ``camvistra._native`` pybind11 extension.

The extension links against the SDK shared libraries (CAMSDK, Logger,
DeviceEnumeration, NetStreamSDK, ONVIF SDKs) plus their FFmpeg/GStreamer
dependencies. On Windows those DLLs are not on the default search path, so
the directories are registered with ``os.add_dll_directory`` before import.

Search order for the SDK binaries:
  1. ``CAMVISTRA_SDK_BIN`` (os.pathsep separated list)
  2. the frozen application directories (PyInstaller builds: ``_internal``
     and the executable's folder)
  3. ``<repo>/Source/x64/Release`` (developer checkout on Windows)
  4. ``<repo>/Source/build/lib/Ubuntu_<version>/<amd64|arm64>``, then
     ``<repo>/Source/lib/Ubuntu_<version>/<amd64|arm64>`` (developer checkout
     on Linux; also the extension's runpath), see ``sdk_paths``

On Linux the extension itself is looked up in the same folders (after the
package folder): it differs per Ubuntu release and architecture, like the
SDK libraries, and lives next to them.

Import PyQt5 *before* this module: the SDK directory also contains Qt 5.14
DLLs from the C++ build, and PyQt5 must bind to its own Qt 5.15 copies.
"""

from __future__ import annotations

import atexit
import os
import sys
from pathlib import Path

from camvistra.sdk_paths import default_sdk_lib_dirs


def sdk_binary_dirs() -> list[Path]:
    dirs: list[Path] = []
    env = os.environ.get("CAMVISTRA_SDK_BIN")
    if env:
        dirs += [Path(p) for p in env.split(os.pathsep) if p]
    if getattr(sys, "frozen", False):
        # PyInstaller 6 puts bundled binaries in _internal (sys._MEIPASS).
        meipass = getattr(sys, "_MEIPASS", None)
        if meipass:
            dirs.append(Path(meipass))
        dirs.append(Path(sys.executable).parent)
    dirs += default_sdk_lib_dirs()
    return [d for d in dirs if d.is_dir()]


if sys.platform == "win32":
    # Load PyQt5's own Qt 5.15 DLLs first: the SDK directory also contains
    # the C++ build's Qt 5.14 DLLs, which must not be picked up.
    import PyQt5.QtCore, PyQt5.QtGui, PyQt5.QtWidgets, PyQt5.QtQuick  # noqa: F401,E401
    try:
        import PyQt5.QtChart  # noqa: F401  (diagnostics reports)
    except ImportError:  # pragma: no cover
        pass
    for _d in sdk_binary_dirs():
        os.add_dll_directory(str(_d))

# Logger.dll names its folder and files after the app (Documents/CamVistra/Log/
# CamVistra_Log_<time>.txt); it reads this once, when the logger is created.
from camvistra.branding import APP_NAME, LOGGER_APP_NAME_ENV  # noqa: E402
os.environ.setdefault(LOGGER_APP_NAME_ENV, APP_NAME)

if sys.platform != "win32":
    # The extension is built per Ubuntu release (its Python version) and
    # architecture, so a checkout keeps it next to the SDK libraries in
    # lib/Ubuntu_<version>/<arch>, not in this package. Search those folders
    # after the package's own one (where an installed build puts it).
    import camvistra as _package
    _package.__path__ += [str(_d) for _d in sdk_binary_dirs() if str(_d) not in _package.__path__]

from camvistra import _native as sdk  # noqa: E402  (after DLL paths are set)

Result = sdk.Result

if os.environ.get("CAMVISTRA_CRASH_TRACE") == "1":
    # Print faulting module+offset and a native back-trace on hard crashes.
    sdk.install_crash_trace()

_app_logger: "sdk.Logger | None" = None


def app_logger() -> "sdk.Logger":
    """Process-wide SDK logger used for application log records."""
    global _app_logger
    if _app_logger is None:
        _app_logger = sdk.Logger()
    return _app_logger


@atexit.register
def _shutdown() -> None:
    # The native Logger singleton outlives the interpreter; drop any Python
    # callback it holds before Python finalises.
    try:
        sdk.Logger().clearLogCallback()
    except Exception:  # pragma: no cover - best effort during shutdown
        pass


__all__ = ["sdk", "Result", "app_logger", "sdk_binary_dirs"]
