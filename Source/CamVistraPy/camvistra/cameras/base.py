"""Base class for the per-camera HID/UVC-extension controllers.

C++ structure (per camera)          Python structure
--------------------------          ----------------
<Cam>_Model  (QObject, logic)  ->   one QObject subclass of CameraController:
<Cam>_Controller (pass-through)     slots = the C++ Controller's Q_INVOKABLEs,
                                    bodies = the C++ Model's logic.

The C++ Controllers only forwarded calls and re-emitted the Model's signals,
so merging the two keeps behaviour identical while halving the code.

Conventions for subclasses
    * ``SDK_CLASS`` is the pybind11 class from ``camvistra._native``.
    * Signal names/argument types and slot names/argument types must match the
      C++ Controller header exactly - QML/JS depend on them.
      ``tools/check_controller_parity.py`` verifies this.
    * Enums from the C++ Controller (``Q_ENUMS``) are nested ``enum.IntEnum``
      classes registered with ``Q_ENUM`` so QML can use ``See3CAMCU200.X``.
    * Every SDK call goes through the bound ``self._cam``; SDK getters return
      ``(ok, value)`` tuples (see tools/gen_camera_bindings.py).
"""

from __future__ import annotations

import sys

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot

IS_WINDOWS = sys.platform == "win32"


class CameraController(QObject):
    statusChanged = pyqtSignal(str, arguments=['status'])

    SDK_CLASS: type | None = None

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        if self.SDK_CLASS is None:
            raise TypeError(f"{type(self).__name__}.SDK_CLASS is not set")
        self._cam = self.SDK_CLASS()
        self._fd = -1

    # ------------------------------------------------------------------
    # Initialisation (identical across the See3CAM controllers)
    # ------------------------------------------------------------------

    @pyqtSlot(int, result=int)
    def initialize(self, fileDes: int) -> int:
        """Linux: attach to the camera's HID node file descriptor."""
        self._fd = fileDes
        self._cam.setHidFd(fileDes)
        return 1

    @pyqtSlot(str, result=int)
    def initializeFromDevicePath(self, devicePath: str) -> int:
        """Windows: open the HID/extension unit from the device path."""
        if not IS_WINDOWS:
            return 0
        return 1 if self._cam.initFromDevicePath(devicePath) else 0

    @pyqtSlot()
    def deinitExtensionUnit(self) -> None:
        if IS_WINDOWS:
            self._cam.deinitExtensionUnit()

    # ------------------------------------------------------------------
    # Helpers for the common Model patterns
    # ------------------------------------------------------------------

    def _set(self, ok: bool, success: str, failure: str) -> bool:
        """Emit the Model's status message for a setter and return ``ok``."""
        self.statusChanged.emit(success if ok else failure)
        return bool(ok)

    @staticmethod
    def _unpack(result) -> tuple[bool, object]:
        """Normalise an SDK getter result to ``(ok, value)``."""
        if isinstance(result, tuple):
            return bool(result[0]), (result[1] if len(result) == 2 else result[1:])
        return bool(result), None
