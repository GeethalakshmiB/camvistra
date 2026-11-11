"""Build script for CamVistra.

Builds the ``camvistra._native`` pybind11 extension against the prebuilt SDK
libraries produced by the existing C++ build (CamVistra.sln / CMake).

    python tools/gen_camera_bindings.py      # regenerate bindings (optional)
    python setup.py build_ext                # Linux: build/lib/Ubuntu_<version>/<arch>/camvistra/_native*.so,
                                             # copied next to the SDK libraries it links against
    python setup.py build_ext --inplace      # Windows: camvistra/_native*.pyd

Environment overrides:
    CAMVISTRA_SDK_LIB_DIR   directory containing CAMSDK.lib / libCAMSDK.so ...
                            (default: ../x64/Release on Windows; on Linux
                            ../build/lib/Ubuntu_<version>/<amd64|arm64>, else
                            ../lib/Ubuntu_<version>/<amd64|arm64>)
    CAMVISTRA_TURBOJPEG_DIR libjpeg-turbo prefix (include/ + lib/)
"""

from __future__ import annotations

import importlib.util
import os
import shutil
import subprocess
import sys
from pathlib import Path

from pybind11.setup_helpers import Pybind11Extension, build_ext
from setuptools import find_packages, setup

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent
WIN = sys.platform == "win32"
PLAT = "windows" if WIN else "linux"

def _load_sdk_paths():
    # Load camvistra/sdk_paths.py on its own: importing the camvistra package
    # would pull in PyQt5.
    spec = importlib.util.spec_from_file_location("_camvistra_sdk_paths", HERE / "camvistra" / "sdk_paths.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _default_sdk_lib_dir() -> Path:
    if WIN:
        return SOURCE / "x64/Release"
    # CMake writes the SDKs to build/lib/Ubuntu_<version>/<arch>. Never fall
    # through silently: the linker would pick up stale SDK copies elsewhere.
    candidates = _load_sdk_paths().default_sdk_lib_dirs()
    for cand in candidates:
        if (cand / "libCAMSDK.so").exists():
            return cand
    sys.exit("libCAMSDK.so not found in " + " or ".join(str(c) for c in candidates)
             + "; build the SDKs or set CAMVISTRA_SDK_LIB_DIR")


# Absolute: it is also baked into the extension's runpath.
sdk_lib_dir = Path(os.environ.get("CAMVISTRA_SDK_LIB_DIR") or _default_sdk_lib_dir()).resolve()

include_dirs = [
    HERE / "native",
    SOURCE / "Logger",
    SOURCE / "CAMSDK" / "include",
    SOURCE / "CAMSDK" / "include" / "platform" / PLAT,
    SOURCE / "DeviceEnumeration" / "include",
    SOURCE / "UsbDeviceEnumeration" / "include",
    SOURCE / "UsbDeviceEnumeration" / "include" / "platform" / PLAT,
    SOURCE / "NetworkDeviceEnumeration",
    SOURCE / "AudioDeviceEnumeration" / "include",
    SOURCE / "StreamingSDK" / "NetStreamSDK",
    SOURCE / "OnvifSDK" / "ShelfVistaSDK",
    SOURCE / "OnvifSDK" / "RoutecamOnvifSDK",
    SOURCE / "CamVistra",  # turbojpeg.h
]

subprocess.run(
    [sys.executable, str(HERE / "tools" / "gen_camera_bindings.py"),
     "--platform", "win32" if WIN else "linux"],
    cwd=HERE,
    check=True,
)

sources = sorted(str(p.relative_to(HERE)) for p in (HERE / "native").rglob("*.cpp"))

if WIN:
    libraries = ["CAMSDK", "Logger", "DeviceEnumeration", "UsbDeviceEnumeration",
                 "NetworkDeviceEnumeration", "AudioDeviceEnumeration", "NetStreamSDK",
                 "ShelfVistaOnvifSDK", "RoutecamOnvifSDK", "turbojpeg",
                 "setupapi", "hid", "ole32", "mfplat", "mfuuid", "strmiids"]
    define_macros = [("UNICODE", None), ("_UNICODE", None), ("WIN32", None),
                     ("_WINDOWS", None), ("NOMINMAX", None)]
    extra_compile_args = ["/utf-8", "/wd4251", "/wd4996", "/wd4244", "/wd4267", "/bigobj"]
    turbo = Path(os.environ.get("CAMVISTRA_TURBOJPEG_DIR", r"C:\libjpeg-turbo64"))
    include_dirs.append(turbo / "include")
    library_dirs = [sdk_lib_dir, turbo / "lib"]
else:
    libraries = ["CAMSDK", "Logger", "DeviceEnumerationSDK", "UsbDeviceEnumerationSDK",
                 "NetworkDeviceEnumerationSDK", "AudioDeviceEnumerationSDK", "NetStreamSDK",
                 "ShelfVistaSDK", "RoutecamSDK", "turbojpeg"]
    define_macros = []
    extra_compile_args = ["-Wno-unused-variable"]
    library_dirs = [sdk_lib_dir]

class PlatformBuildExt(build_ext):
    """build_ext writing to build/lib/Ubuntu_<version>/<amd64|arm64> on Linux.

    Object files go to build/temp/Ubuntu_<version>/<amd64|arm64>, so builds for
    different Ubuntu releases or architectures do not mix. --build-lib and
    --build-temp on the command line still win.
    """

    def finalize_options(self):
        if not WIN:
            sub = _load_sdk_paths().platform_lib_subdir()  # lib/Ubuntu_<version>/<arch>
            if self.build_lib is None:
                self.build_lib = str(HERE / "build" / sub)
            if self.build_temp is None:
                self.build_temp = str(HERE / "build" / "temp" / sub.relative_to("lib"))
        super().finalize_options()

    def run(self):
        super().run()
        if WIN:
            return
        # The extension differs per Ubuntu release (Python version) and
        # architecture, like the SDK libraries: put a copy next to them in
        # the folder it was linked against. camvistra.native finds it there.
        for ext in self.extensions:
            built = Path(self.get_ext_fullpath(ext.name))
            if built.exists():
                target = sdk_lib_dir / built.name
                shutil.copy2(built, target)
                print(f"copied {built.name} -> {sdk_lib_dir}")


ext = Pybind11Extension(
    "camvistra._native",
    sources,
    include_dirs=[str(p) for p in include_dirs],
    library_dirs=[str(p) for p in library_dirs],
    libraries=libraries,
    define_macros=define_macros,
    extra_compile_args=extra_compile_args,
    runtime_library_dirs=[] if WIN else ["$ORIGIN", str(sdk_lib_dir)],
    cxx_std=17,
)

setup(
    name="camvistra",
    version="1.0.18",
    description="CamVistra camera application (PyQt5 port)",
    packages=find_packages(include=["camvistra", "camvistra.*"]),
    package_data={"camvistra": ["*.pyd", "*.so"]},
    ext_modules=[ext],
    cmdclass={"build_ext": PlatformBuildExt},
    python_requires=">=3.8",
    entry_points={"gui_scripts": ["camvistra = camvistra.__main__:main"]},
)
