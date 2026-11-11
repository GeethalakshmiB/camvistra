"""Device list tracking (port of CamVistra/Model/src/DeviceModel.cpp).

``get_devices()`` is called every 2 s from DeviceController's scan thread.
It diffs the DeviceManager enumeration against the previous scan and emits
``deviceAdded`` / ``deviceRemoved`` so the QML device list updates without
being rebuilt on every scan. Wi-Fi removals are debounced (3 scans) and
guarded by a ping, because Wi-Fi cameras routinely drop out of WS-Discovery.
"""

from __future__ import annotations

import subprocess
import sys
import threading

from PyQt5.QtCore import QObject, pyqtSignal

from camvistra.native import Result, sdk

_NETWORK = ("Ethernet", "Wi-Fi")
# Camera transports listed in the UI's local-camera rows; QML sees them all
# as type "Usb" with the real transport in "transportType".
_LOCAL_CAMERA_TYPES = ("Usb", "GMSL", "MIPI", "PCI")
IS_WINDOWS = sys.platform == "win32"
# Windows: scans a known Wi-Fi camera must be missing before it is removed.
WIFI_DISCONNECT_CONFIRM_SCANS = 4


def _is_local_camera(dtype: str) -> bool:
    return dtype in _LOCAL_CAMERA_TYPES


def _ui_device_type(dtype: str) -> str:
    return "Usb" if _is_local_camera(dtype) else dtype

# The C++ application owns exactly one DeviceManager. The SDK enumerators
# share process-wide state (COM, sockets, PulseAudio), so the port also uses
# a single instance and never enumerates from two threads at once.
_shared_manager = None
_manager_lock = threading.Lock()


def shared_device_manager():
    global _shared_manager
    with _manager_lock:
        if _shared_manager is None:
            _shared_manager = sdk.DeviceManager()
        return _shared_manager


def _network_entry(dev: dict, manually_added: bool | None = False) -> dict:
    entry = {
        "deviceName": dev["DeviceName"],
        "deviceIP": dev["DeviceIP"],
        "devicePath": dev["DeviceIP"],
        "type": dev["type"],
    }
    if manually_added is not None:
        entry["manuallyAdded"] = manually_added
    return entry


def _usb_entry(dev: dict, manually_added: bool | None = False, serial: bool = True) -> dict:
    entry = {
        "deviceName": dev["DeviceName"],
        "devicePath": dev["devicePath"],
        "deviceVid": dev["vid"],
        "devicePid": dev["pid"],
    }
    if serial:
        entry["deviceSerialNo"] = dev["serialNo"]
    entry["type"] = dev["type"]
    if manually_added is not None:
        entry["manuallyAdded"] = manually_added
    return entry


class DeviceModel(QObject):
    deviceAdded = pyqtSignal("QVariantMap", int)
    deviceRemoved = pyqtSignal("QVariantList")
    deviceStatus = pyqtSignal(str)

    ignore_usb_devices = False  # static DeviceModel::ignoreUsbDevices

    def __init__(self, manager=None, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._mgr = manager if manager is not None else shared_device_manager()
        self.device_count = 0
        self.dev_cnt = 0
        self.count = 0
        self.wifi_missing_streak = 0
        self.selected_dev = ""
        self.selected_dev_type = ""
        self.current_device_list: list[dict] = []
        self.previous_usb_paths: set[str] = set()
        self.last_known_wifi_ips: set[str] = set()
        self.manually_added_ips: set[str] = set()

    # ------------------------------------------------------------------
    def _enumerate(self) -> tuple[int, list[dict], int]:
        with _manager_lock:
            return self._mgr.enumerateAllDevices()

    def is_ip_already_enumerated(self, ip_address: str) -> bool:
        res, devices, _ = self._enumerate()
        if res != Result.Ok:
            return False
        return any(d["type"] in _NETWORK and d["DeviceIP"] == ip_address for d in devices)

    def add_device_to_the_list(self, ip_address: str) -> bool:
        return self._add_manual(ip_address, "Ethernet", ip_address, "Device manually added: ")

    def add_wifi_device_to_the_list(self, ip_address: str) -> bool:
        # Wi-Fi cameras have no friendly name; the UI shows the web URL.
        return self._add_manual(ip_address, "Wi-Fi", f"http://{ip_address}:8080",
                                "WiFi device manually added: ")

    def _add_manual(self, ip: str, dev_type: str, name: str, ok_message: str) -> bool:
        # 1. Reject duplicate manual entries
        if ip in self.manually_added_ips:
            self.deviceStatus.emit("Device already manually added: " + ip)
            return False
        # 2. Reject devices already found by enumeration
        if self.is_ip_already_enumerated(ip):
            self.deviceStatus.emit("Device already enumerated in the list: " + ip)
            return False
        new_device = {"deviceName": name, "deviceIP": ip, "devicePath": ip,
                      "type": dev_type, "manuallyAdded": True}
        self.manually_added_ips.add(ip)
        # Bump only the total; dev_cnt kept in sync to suppress a spurious removal
        self.device_count += 1
        self.dev_cnt = self.device_count
        self.selected_dev_type = dev_type
        self.deviceAdded.emit(new_device, self.device_count)
        self.deviceStatus.emit(ok_message + ip)
        return True

    def remove_manually_added_device(self) -> bool:
        if not self.manually_added_ips:
            self.deviceStatus.emit("No manually added devices found")
            return False
        self.manually_added_ips.clear()
        if self.device_count > 0:
            self.device_count -= 1
        self.dev_cnt = self.device_count

        remaining: list[dict] = []
        res, devices, _ = self._enumerate()
        if res == Result.Ok:
            for dev in devices:
                if dev["type"] in _NETWORK:
                    remaining.append(_network_entry(dev))
                else:
                    if dev["type"] == "Usb" and DeviceModel.ignore_usb_devices:
                        continue
                    remaining.append(_usb_entry(dev))
        self.deviceRemoved.emit(remaining)
        self.deviceStatus.emit("All manually added devices removed")
        return True

    # ------------------------------------------------------------------
    @staticmethod
    def _local_camera_paths(devices: list[dict]) -> set[str]:
        return {d["devicePath"] for d in devices if _is_local_camera(d["type"])}

    @staticmethod
    def _build_device_list(devices: list[dict]) -> list[dict]:
        """deviceRemoved() payload (C++ DeviceModel::buildDeviceList)."""
        out: list[dict] = []
        for dev in devices:
            dtype = dev["type"]
            is_network = dtype in _NETWORK
            if not is_network and dtype == "Usb" and DeviceModel.ignore_usb_devices:
                continue
            entry = {"deviceName": dev["DeviceName"]}
            if is_network:
                entry["deviceIP"] = dev["DeviceIP"]
                entry["devicePath"] = dev["DeviceIP"]
            else:
                entry["devicePath"] = dev["devicePath"]
                entry["deviceVid"] = dev["vid"]
                entry["devicePid"] = dev["pid"]
                entry["deviceSerialNo"] = dev["serialNo"]
            entry["type"] = _ui_device_type(dtype)
            if _is_local_camera(dtype):
                entry["transportType"] = dtype
            entry["manuallyAdded"] = False
            out.append(entry)
        return out

    def get_devices(self) -> int:
        """One enumeration pass; emits deviceAdded/deviceRemoved for changes.

        Mirrors C++ DeviceModel::getDevices(). USB-style (USB/GMSL/MIPI/PCI)
        changes are detected from the set of camera paths, not from
        ``selected_dev_type``: that ends up as the type of the *last*
        enumerated device (often the camera's own "Audio" entry), so it
        cannot tell whether a USB camera was plugged or unplugged.
        """
        self.device_count = 0
        self.current_device_list = []

        res, devices, self.device_count = self._enumerate()
        current_local_paths = self._local_camera_paths(devices)

        # Count consecutive scans that miss the Wi-Fi camera. Any scan that
        # lists it restarts the count, so a flicker never removes it.
        wifi_listed = res == Result.Ok and any(d["type"] == "Wi-Fi" for d in devices)
        wifi_missing = not wifi_listed and bool(self.last_known_wifi_ips)
        if wifi_listed:
            self.wifi_missing_streak = 0
            self.count = 0
        elif wifi_missing:
            self.wifi_missing_streak += 1

        if res == Result.Ok:
            # Nothing is emitted for an empty (but successful) enumeration.
            if self.device_count > 0:
                # A periodic scan with the same devices must not re-emit every
                # entry: those queued signals rebuild QML device state and
                # stall rendering. Equality is actionable only for a
                # same-count USB replacement.
                same_count_usb_change = (self.dev_cnt == self.device_count
                                         and current_local_paths != self.previous_usb_paths)
                if self.dev_cnt < self.device_count or same_count_usb_change:
                    self._on_devices_added(devices, current_local_paths)
                elif self.dev_cnt > self.device_count:
                    if not self._on_devices_removed(devices, current_local_paths, wifi_missing):
                        return 1
            self.previous_usb_paths = current_local_paths
            return 1

        if res == Result.Failed:
            # Only act when devices were reported before and none are now.
            if self.dev_cnt != self.device_count and self.device_count == 0:
                self._on_enumeration_empty(wifi_missing)
            return 1

        return 0

    def _on_devices_added(self, devices: list[dict], current_local_paths: set[str]) -> None:
        self.dev_cnt = self.device_count
        # Emit one deviceAdded per entry; selected_dev_type ends up as the
        # last entry's type.
        for dev in devices:
            dtype = dev["type"]
            if dtype in _NETWORK:
                entry = _network_entry(dev)
                # The first network device ever seen is pre-selected in the UI.
                if not self.selected_dev:
                    entry["isChecked"] = True
                    self.selected_dev = dev["DeviceName"][:255]
                ip = dev["DeviceIP"]
                if dtype == "Wi-Fi":
                    # A manual entry that is now discovered becomes a normal one.
                    self.selected_dev_type = "Wi-Fi"
                    self.last_known_wifi_ips.add(ip)
                    self.manually_added_ips.discard(ip)
                    self.count = 0
                else:
                    self.selected_dev_type = "Ethernet"
                    self.manually_added_ips.discard(ip)
                self.deviceAdded.emit(entry, self.device_count)
            elif _is_local_camera(dtype):
                if dtype == "Usb" and DeviceModel.ignore_usb_devices:
                    self.device_count -= 1
                    continue
                entry = _usb_entry(dev)
                entry["type"] = "Usb"
                entry["transportType"] = dtype
                self.selected_dev_type = "Usb"
                self.deviceAdded.emit(entry, self.device_count)
            elif dtype == "Audio":
                self.selected_dev_type = "Audio"
                self.deviceAdded.emit(_usb_entry(dev, serial=False), self.device_count)

        # USB simultaneous plug + unplug detection
        if self.selected_dev_type == "Usb" or self.previous_usb_paths:
            if self.previous_usb_paths - current_local_paths:
                remaining = []
                for d in devices:
                    entry = _usb_entry(d, manually_added=None)
                    entry["type"] = _ui_device_type(d["type"])
                    remaining.append(entry)
                self.deviceRemoved.emit(remaining)
            self.previous_usb_paths = current_local_paths

    def _on_devices_removed(self, devices: list[dict], current_local_paths: set[str],
                            wifi_missing: bool) -> bool:
        """Returns False when the removal is deferred (debounce / guard), in
        which case the caller must not update the USB baseline."""
        # Hold every removal while the Wi-Fi camera has been missing for fewer
        # than WIFI_DISCONNECT_CONFIRM_SCANS consecutive scans.
        if IS_WINDOWS and wifi_missing and self.wifi_missing_streak < WIFI_DISCONNECT_CONFIRM_SCANS:
            return False

        if wifi_missing:
            # Debounced: Wi-Fi cameras drop out of discovery intermittently.
            if not IS_WINDOWS:
                self.count += 1
                if self.count < 3:
                    return False
            real_wifi_found = any(d["type"] == "Wi-Fi" for d in devices)
            # Keep manual Wi-Fi entries while no real Wi-Fi device is found.
            if not real_wifi_found and self.manually_added_ips:
                self.count = 0
                return False
            # Discovery can miss a live camera; a reply cancels the removal.
            if any(self.check_ip_connection(ip) for ip in list(self.last_known_wifi_ips)):
                self.count = 0
                self.wifi_missing_streak = 0
                return False
            self.current_device_list = self._build_device_list(devices)
            self.last_known_wifi_ips.clear()
            self.manually_added_ips.clear()
            self.dev_cnt = self.device_count
            self.count = 0
            self.wifi_missing_streak = 0
            self.deviceRemoved.emit(self.current_device_list)
        elif self.selected_dev_type == "Ethernet":
            real_ethernet_found = any(d["type"] == "Ethernet" for d in devices)
            if not real_ethernet_found and self.manually_added_ips:
                return False
            self.current_device_list = self._build_device_list(devices)
            self.manually_added_ips.clear()
            self.dev_cnt = self.device_count
            self.deviceRemoved.emit(self.current_device_list)
        elif self.previous_usb_paths or current_local_paths:
            self.current_device_list = self._build_device_list(devices)
            self.previous_usb_paths = set(current_local_paths)  # sync baseline after removal
            self.dev_cnt = self.device_count
            self.deviceRemoved.emit(self.current_device_list)
        else:
            # Audio, or a non-Wi-Fi device removed while Wi-Fi is still listed.
            self.current_device_list = self._build_device_list(devices)
            self.dev_cnt = self.device_count
            self.deviceRemoved.emit(self.current_device_list)
        return True

    def _on_enumeration_empty(self, wifi_missing: bool) -> None:
        if wifi_missing:
            # Wait for several consecutive missed scans before probing.
            if IS_WINDOWS and self.wifi_missing_streak < WIFI_DISCONNECT_CONFIRM_SCANS:
                return
            self.count += 1
            if self.manually_added_ips:
                return
            if any(self.check_ip_connection(ip) for ip in list(self.last_known_wifi_ips)):
                self.count = 0
                self.wifi_missing_streak = 0
                return
            # On Windows the streak already confirmed the disconnect.
            if IS_WINDOWS or self.count == 2:
                self.dev_cnt = 0
                self.count = 0
                self.last_known_wifi_ips.clear()
                self.manually_added_ips.clear()
                self.deviceRemoved.emit([])
        elif self.selected_dev_type == "Ethernet":
            if self.manually_added_ips:
                return
            self.dev_cnt = 0
            self.count = 0
            self.manually_added_ips.clear()
            self.deviceRemoved.emit([])
        elif self.previous_usb_paths:
            self.previous_usb_paths.clear()  # reset baseline on full enumeration failure
            self.dev_cnt = 0
            self.count = 0
            self.deviceRemoved.emit([])
        elif self.selected_dev_type == "Audio":
            self.dev_cnt = 0
            self.count = 0
            self.deviceRemoved.emit([])

    @staticmethod
    def check_ip_connection(ip_address: str) -> bool:
        """One ping with a 1 s reply timeout (3 s overall), like the C++ QProcess call."""
        if sys.platform == "win32":
            args = ["ping", "-n", "1", "-w", "1000", ip_address]
            flags = subprocess.CREATE_NO_WINDOW
        else:
            args = ["ping", "-c", "1", "-W", "1", ip_address]
            flags = 0
        try:
            proc = subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                  timeout=3, creationflags=flags)
        except (subprocess.TimeoutExpired, OSError):
            return False
        return proc.returncode == 0
