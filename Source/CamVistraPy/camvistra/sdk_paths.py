"""Where the SDK shared libraries live in a developer checkout.

On Linux the CMake build writes them per platform and architecture
(see Source/cmake/PlatformLibDir.cmake):

    Source/build/lib/Ubuntu_<version>/<amd64|arm64>/libCAMSDK.so ...

On Windows they are in Source/x64/Release (Visual Studio solution).

Standard library only: setup.py and the PyInstaller spec load this file
directly, without importing the camvistra package (which needs PyQt5).

Overrides (match the CMake cache variables):
    CAMVISTRA_PLATFORM   e.g. Ubuntu_20.04
    CAMVISTRA_ARCH       amd64 | arm64
"""

from __future__ import annotations

import os
import platform
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[2]

_ARCH_ALIASES = {"x86_64": "amd64", "amd64": "amd64", "x64": "amd64",
                 "aarch64": "arm64", "arm64": "arm64"}


def platform_name() -> str:
    """``Ubuntu_<VERSION_ID>`` from /etc/os-release (e.g. ``Ubuntu_22.04``)."""
    env = os.environ.get("CAMVISTRA_PLATFORM")
    if env:
        return env
    fields = {}
    try:
        with open("/etc/os-release", encoding="utf-8") as fh:
            for line in fh:
                key, sep, value = line.strip().partition("=")
                if sep:
                    fields[key] = value.strip('"')
    except OSError:
        pass
    version = fields.get("VERSION_ID", "")
    return f"Ubuntu_{version}" if version else "Ubuntu"


def arch_name() -> str:
    """``amd64`` or ``arm64`` for this machine."""
    env = os.environ.get("CAMVISTRA_ARCH")
    if env:
        return env
    machine = platform.machine().lower()
    return _ARCH_ALIASES.get(machine, machine)


def platform_lib_subdir() -> Path:
    """``lib/Ubuntu_<version>/<arch>`` (relative)."""
    return Path("lib") / platform_name() / arch_name()


def default_sdk_lib_dirs() -> list[Path]:
    """Candidate SDK library folders, most specific first (existing or not)."""
    if sys.platform == "win32":
        return [SOURCE / "x64" / "Release"]
    sub = platform_lib_subdir()
    return [SOURCE / "build" / sub, SOURCE / sub]
