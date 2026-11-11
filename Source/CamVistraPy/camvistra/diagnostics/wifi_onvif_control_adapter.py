"""Port of WifiOnvifControlAdapter.cpp.

WifiOnvif has no generic property-ID control API - only named setters
(setPan, setTilt, setAPConfig, setSTAConfig, setResolution,
startRecording/stopRecording). Each is mapped to the same
{control name, value, timestamp} event the other adapters produce.
"""

from __future__ import annotations

from camvistra.diagnostics.uvc_control_provider import IUvcControlProvider


class WifiOnvifControlAdapter(IUvcControlProvider):
    def report_pan(self, pan: int) -> None:
        self._report("Pan", pan)

    def report_tilt(self, tilt: int) -> None:
        self._report("Tilt", tilt)

    def report_resolution(self, resolution: str) -> None:
        # Not a numeric control: value 1 is a "changed" marker and the actual
        # resolution is folded into the control name (as in C++).
        self._report(f"Resolution: {resolution}", 1)

    def report_recording_state(self, recording: bool) -> None:
        self._report("Recording", 1 if recording else 0)

    def report_ap_config_changed(self) -> None:
        self._report("AP Config", 1)

    def report_sta_config_changed(self) -> None:
        self._report("STA Config", 1)

    def _report(self, control_name: str, value: int) -> None:
        self._emit(control_name, value)
