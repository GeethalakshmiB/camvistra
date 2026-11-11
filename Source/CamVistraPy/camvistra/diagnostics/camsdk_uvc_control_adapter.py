"""Port of CamsdkUvcControlAdapter.cpp.

Wraps the single USB/See3CAM control chokepoint
(UsbCameraModel.set_camera_control_property -> CAMSDK SetCameraControlProperty).
The model calls ``report_control_change(readable_name, value)`` after CAMSDK
confirms the set succeeded; this just timestamps and re-emits it.
"""

from __future__ import annotations

from camvistra.diagnostics.uvc_control_provider import IUvcControlProvider


class CamsdkUvcControlAdapter(IUvcControlProvider):
    def report_control_change(self, control_id: str, value) -> None:
        self._emit(control_id, value)
