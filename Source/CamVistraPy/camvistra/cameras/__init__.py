"""Per-camera HID/UVC-extension controllers.

``REGISTRY`` mirrors the camera section of CamVistra/main.cpp: which
controller class backs which QML context property, and under which QML
module/type name its enums are registered (``qmlRegisterUncreatableType``).
It also names the C++ controller header each class was ported from, which
``tools/check_controller_parity.py`` uses to verify the Python API.
"""

from __future__ import annotations

import importlib
from dataclasses import dataclass


@dataclass(frozen=True)
class CameraEntry:
    module: str            # module in camvistra.cameras
    cls: str               # controller class name
    cpp_header: str        # CamVistra/Controller/include/<header>
    context: str           # QML context property name
    qml_type: str | None   # QML module + type name (None: not registered)

    def load(self) -> type:
        mod = importlib.import_module(f"camvistra.cameras.{self.module}")
        return getattr(mod, self.cls)


REGISTRY: list[CameraEntry] = [
    CameraEntry("ecam212_usb", "Ecam212USB_UvcExt_Controller", "E-cam212_UVCExt_Controller.h", "ecam212usbUvcextController", None),
    CameraEntry("ecam16_usb", "ECAM16USB_Controller", "E-cam16_USB_Controller.h", "ecam16usbController", None),
    CameraEntry("ecam82_usb", "ECAM82USB_Controller", "e-CAM82_USB_Controller.h", "ecam82usbController", None),
    CameraEntry("see3cam_130e", "See3CAM_130E_Controller", "See3CAM_130E_Controller.h", "see3cam130eController", "See3CAM130E"),
    CameraEntry("see3cam_1318_tc", "See3CAM_1318_TC_Controller", "See3CAM_1318_TC_Controller.h", "see3cam1318tcController", "See3CAM1318_TC"),
    CameraEntry("see3cam_cu31", "See3CAM_CU31_Controller", "See3CAM_CU31_Controller.h", "see3camcu31Controller", "See3CAMCU31"),
    CameraEntry("see3cam_cu83", "See3CAM_CU83_Controller", "See3CAM_CU83_Controller.h", "see3camcu83Controller", "See3CAMCU83"),
    CameraEntry("see3cam_27cug", "See3CAM_27CUG_Controller", "See3CAM_27CUG_Controller.h", "see3cam27cugController", "See3CAM27CUG"),
    CameraEntry("see3cam_37cug", "See3CAM_37CUG_Controller", "See3CAM_37CUG_Controller.h", "see3cam37cugController", "See3CAM37CUG"),
    CameraEntry("see3cam_cu22", "See3CAM_CU22_Controller", "See3CAM_CU22_Controller.h", "see3camcu22Controller", "See3CAMCU22"),
    CameraEntry("see3cam_cu130", "See3CAM_CU130_Controller", "See3CAM_CU130_Controller.h", "see3camcu130Controller", "See3CAMCU130"),
    CameraEntry("see3cam_cu135m_h01r1", "See3CAM_CU135M_H01R1_Controller", "See3CAM_CU135M_H01R1_Controller.h", "see3camcu135mh01r1Controller", "See3CAMCU135M_H01R1"),
    CameraEntry("see3cam_cu135", "See3CAM_CU135_Controller", "See3CAM_CU135_Controller.h", "see3camcu135Controller", "See3CAMCU135"),
    CameraEntry("see3cam_24cug", "See3CAM_24CUG_Controller", "See3CAM_24CUG_Controller.h", "see3cam24cugController", "See3CAM24CUG"),
    CameraEntry("see3cam_cu81", "See3CAM_CU81_Controller", "See3CAM_CU81_Controller.h", "see3camcu81Controller", "See3CAMCU81"),
    CameraEntry("see3cam_160", "See3CAM_160_Controller", "See3CAM_160_Controller.h", "see3cam160Controller", "See3CAM160"),
    CameraEntry("see3cam_cu84", "See3CAM_CU84_Controller", "See3CAM_CU84_Controller.h", "see3camcu84Controller", "See3CAMCU84"),
    CameraEntry("see3cam_cu27", "See3CAM_CU27_Controller", "See3CAM_CU27_Controller.h", "see3camcu27Controller", "See3CAMCU27"),
    CameraEntry("see3cam_cu512m", "See3CAM_CU512M_Controller", "See3CAM_CU512M_Controller.h", "see3camcu512mController", "See3CAMCU512M"),
    CameraEntry("see3cam_cu200m", "See3CAM_CU200M_Controller", "See3CAM_CU200M_Controller.h", "see3camcu200mController", "See3CAMCU200M"),
    CameraEntry("see3cam_cu200", "See3CAM_CU200_Controller", "See3CAM_CU200_Controller.h", "see3camcu200Controller", "See3CAMCU200"),
    CameraEntry("see3cam_cu58", "See3CAM_CU58_Controller", "See3CAM_CU58_Controller.h", "see3camcu58Controller", "See3CAMCU58"),
    CameraEntry("see3cam_cu55", "See3CAM_CU55_Controller", "See3CAM_CU55_Controller.h", "see3camcu55Controller", "See3CAMCU55"),
    CameraEntry("see3cam_cu55_mh", "See3CAM_CU55_MH_Controller", "See3CAM_CU55_MH_Controller.h", "see3camcu55mhController", "See3CAMCU55MH"),
    CameraEntry("densicam", "DensiCAM_Controller", "DensiCAM_Controller.h", "densicamController", "DensiCAM"),
]
