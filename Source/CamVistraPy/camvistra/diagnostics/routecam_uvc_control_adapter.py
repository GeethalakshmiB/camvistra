"""Port of RoutecamUvcControlAdapter.cpp.

Wraps RoutecamOnvifController's control chokepoint (setCameraControlProperty):
same method shape as CamsdkUvcControlAdapter, different SDK underneath.
"""

from __future__ import annotations

from camvistra.diagnostics.uvc_control_provider import IUvcControlProvider


class RoutecamUvcControlAdapter(IUvcControlProvider):
    def report_control_change(self, control_id: str, value) -> None:
        self._emit(control_id, value)
