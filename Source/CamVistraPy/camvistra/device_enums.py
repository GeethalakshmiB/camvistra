"""Supported-camera registry (port of CamVistra/DeviceEnums.h).

Maps a USB "VID:PID" pair to the camera type used by QML
(``DeviceEnums.See3CAM_CU200`` etc.) and to the base name of the camera's
JSON control description in ``qrc:/View/JSON``.
"""

from __future__ import annotations

import enum
from typing import NamedTuple

from PyQt5.QtCore import Q_ENUM, QObject, pyqtSlot


class DeviceEnums(QObject):
    class DeviceType(enum.IntEnum):
        Unknown = -1
        See3CAM_130E = 0
        See3CAM_130E_H02R1 = 1
        See3CAM_130E_H03R1 = 2
        See3CAM_CU130 = 3
        See3CAM_CU135M_H01R1 = 4
        See3CAM_24CUG = 5
        See3CAM_CU81 = 6
        See3CAM_CU58 = 7
        See3CAM_CU55_CHLCW_H21R1 = 8
        DensiCAM = 9
        ECAM212_USB = 10
        ECAM16_USB = 11
        ECAM82_USB = 12
        See3CAM_160 = 13
        See3CAM_CU84 = 14
        See3CAM_CU512M = 15
        See3CAM_CU135 = 16
        See3CAM_CU22 = 17
        See3CAM_CU27 = 18
        See3CAM_CU200M = 19
        See3CAM_CU200 = 20
        See3CAM_CU200M_H01R1 = 21
        See3CAM_CU55_MH = 22
        See3CAM_CU31 = 23
        See3CAM_CU83 = 24
        See3CAM_27CUG = 25
        See3CAM_37CUG = 26
        See3CAM_1318_TC = 27
    Q_ENUM(DeviceType)

    class DeviceInfo(NamedTuple):
        type: "DeviceEnums.DeviceType"
        jsonFileName: str

    @staticmethod
    def device_registry() -> dict[str, "DeviceEnums.DeviceInfo"]:
        return _REGISTRY

    @staticmethod
    def from_vid_pid(vid: str, pid: str) -> "DeviceEnums.DeviceType":
        info = _REGISTRY.get(f"{vid.upper()}:{pid.upper()}")
        return info.type if info else DeviceEnums.DeviceType.Unknown

    @staticmethod
    def json_file_name_from_vid_pid(vid: str, pid: str) -> str:
        info = _REGISTRY.get(f"{vid.upper()}:{pid.upper()}")
        return info.jsonFileName if info else ""

    @pyqtSlot(str, str, result=int)
    def resolveDevice(self, vid: str, pid: str) -> int:
        """QML calls this with the string VID and PID of a USB device."""
        return int(self.from_vid_pid(vid, pid))


_T = DeviceEnums.DeviceType
_I = DeviceEnums.DeviceInfo

# Key is "VID:PID", e.g. "2560:C0DA".
_REGISTRY: dict[str, DeviceEnums.DeviceInfo] = {
    "2560:C0DA": _I(_T.See3CAM_130E, "See3CAM_130E"),
    "2560:C0DB": _I(_T.See3CAM_130E_H02R1, "See3CAM_130E"),
    "2560:C0DC": _I(_T.See3CAM_130E_H03R1, "See3CAM_130E"),
    "2560:C1D0": _I(_T.See3CAM_CU130, "See3CAM_CU130"),
    "2560:C1D7": _I(_T.See3CAM_CU135M_H01R1, "See3CAM_CU135M_H01R1"),
    "2560:C128": _I(_T.See3CAM_24CUG, "See3CAM_24CUG"),
    "2560:C180": _I(_T.See3CAM_CU81, "See3CAM_CU81"),
    "2560:C15F": _I(_T.See3CAM_CU58, "See3CAM_CU58"),
    "2560:0150": _I(_T.See3CAM_CU55_CHLCW_H21R1, "See3CAM_CU58"),
    "2560:C15C": _I(_T.DensiCAM, "DensiCAM"),
    "2560:012C": _I(_T.ECAM212_USB, "e-CAM212_USB"),
    "2560:C11A": _I(_T.ECAM16_USB, "e-CAM16_USB"),
    "2560:C181": _I(_T.ECAM82_USB, "e-CAM82_USB"),
    "2560:C400": _I(_T.See3CAM_160, "See3CAM_160"),
    "2560:C189": _I(_T.See3CAM_CU84, "See3CAM_CU84"),
    "2560:C158": _I(_T.See3CAM_CU512M, "See3CAM_CU512M"),
    "2560:C1D1": _I(_T.See3CAM_CU135, "See3CAM_CU135"),
    "2560:C126": _I(_T.See3CAM_CU22, "See3CAM_CU22"),
    "2560:C12C": _I(_T.See3CAM_CU27, "See3CAM_CU27"),
    "2560:C542": _I(_T.See3CAM_CU200M, "See3CAM_CU200M"),
    "2560:C540": _I(_T.See3CAM_CU200, "See3CAM_CU200"),
    "2560:C543": _I(_T.See3CAM_CU200M_H01R1, "See3CAM_CU200M_H01R1"),
    "2560:C155": _I(_T.See3CAM_CU55_MH, "See3CAM_CU55_MH"),
    "2560:C137": _I(_T.See3CAM_CU31, "See3CAM_CU31"),
    "2560:C188": _I(_T.See3CAM_CU83, "See3CAM_CU83"),
    "2560:0121": _I(_T.See3CAM_27CUG, "See3CAM_27CUG"),
    "2560:C13A": _I(_T.See3CAM_37CUG, "See3CAM_37CUG"),
    "2560:C0D3": _I(_T.See3CAM_1318_TC, "See3CAM_1318_TC"),
}
