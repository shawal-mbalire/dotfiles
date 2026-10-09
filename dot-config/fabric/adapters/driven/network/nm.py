"""NetworkManagerAdapter — NetworkPort over the NetworkManager D-Bus API.

Service  org.freedesktop.NetworkManager
Objects  /org/freedesktop/NetworkManager, /org/freedesktop/NetworkManager/Devices/N,
         /org/freedesktop/NetworkManager/Devices/N/AccessPoint/M
Uses the native D-Bus interface; no nmcli.
"""

from __future__ import annotations

from typing import Any, cast

from adapters.driven.dbus import BusConnection, Variant
from adapters.driven.observable import Observable, Poller
from domain.logic import dedupe_networks
from domain.models import Network

NM = "org.freedesktop.NetworkManager"
NM_PATH = "/org/freedesktop/NetworkManager"
PROPS = "org.freedesktop.DBus.Properties"
DEV_IFACE = "org.freedesktop.NetworkManager.Device"
WIFI_IFACE = "org.freedesktop.NetworkManager.Device.Wireless"
AP_IFACE = "org.freedesktop.NetworkManager.AccessPoint"
SETTINGS = "org.freedesktop.NetworkManager.Settings"

DEVICE_TYPE_WIFI = 2


def ssid_bytes_to_text(ssid: object, fallback: str = "") -> str:
    if isinstance(ssid, bytes):
        try:
            return ssid.decode("utf-8")
        except UnicodeDecodeError:
            return fallback
    return fallback


def secured_from_flags(wpa_flags: object, rsn_flags: object) -> bool:
    try:
        return int(cast(Any, wpa_flags)) > 0 or int(cast(Any, rsn_flags)) > 0
    except (TypeError, ValueError):
        return False


class NetworkManagerAdapter(Observable[Network]):
    def __init__(self, bus: BusConnection, *, interval: float = 3.0, logger=None) -> None:
        super().__init__(Network())
        self._bus = bus
        self._logger = logger
        self._interval = interval
        self._scanning = False
        self._known_ssids: set[str] = set()
        self._poller = Poller(self._refresh_aps, interval)
        self._failure_listeners: list = []
        self._device_path = ""
        self._bus.on_signal(NM, "DeviceAdded", self._on_device_change)
        self._bus.on_signal(NM, "DeviceRemoved", self._on_device_change)

    def start(self) -> None:
        try:
            self._refresh_all()
        except Exception as exc:  # noqa: BLE001 - surfaces via logger
            self._warn("initial refresh failed", error=str(exc))
            self.notify(Network(available=False))
            return
        self._poller.start()

    def stop(self) -> None:
        self._poller.stop()

    def subscribe_failures(self, listener):
        self._failure_listeners.append(listener)
        return lambda: self._failure_listeners.remove(listener)

    # ── commands ──────────────────────────────────────────────────────────
    def set_wifi_enabled(self, enabled: bool) -> None:
        self._bus.call(
            destination=NM,
            path=NM_PATH,
            interface=PROPS,
            member="Set",
            signature="ssv",
            args=(NM, "WirelessEnabled", Variant("b", enabled)),
        )

    def set_scanning(self, scanning: bool) -> None:
        self._scanning = scanning
        if scanning:
            self.request_scan()
            self._poller.start()  # AP list needs fresh data while shown

    def request_scan(self) -> None:
        if not self._device_path:
            return
        try:
            self._bus.call(
                destination=NM,
                path=self._device_path,
                interface=WIFI_IFACE,
                member="RequestScan",
                signature="a{sv}",
                args=({"visible": Variant("b", True)},),
            )
        except Exception as exc:  # noqa: BLE001
            self._warn("request scan failed", error=str(exc))

    def connect_to(self, name: str) -> None:
        device = self._device_path
        if not device:
            self._emit_failure(name, "No wifi device found")
            return
        connection = self._existing_connection(name)
        if not connection:
            self._emit_failure(name, "NoSecrets")
            return
        try:
            self._bus.call(
                destination=NM,
                path=NM_PATH,
                interface=NM,
                member="ActivateConnection",
                signature="ooo",
                args=(connection, device, "/"),
            )
        except Exception as exc:  # noqa: BLE001
            self._emit_failure(name, str(exc))

    def connect_with_psk(self, name: str, psk: str) -> None:
        if not self._device_path:
            self._emit_failure(name, "No wifi device found")
            return
        connection = {
            "connection": {"type": Variant("s", "802-11-wireless"), "id": Variant("s", name)},
            "802-11-wireless": {
                "ssid": Variant("ay", name.encode()),
                "mode": Variant("s", "infrastructure"),
            },
            "802-11-wireless-security": {
                "key-mgmt": Variant("s", "wpa-psk"),
                "psk": Variant("s", psk),
            },
        }
        try:
            self._bus.call(
                destination=NM,
                path="/org/freedesktop/NetworkManager/Settings",
                interface=SETTINGS,
                member="AddAndActivateConnection",
                signature="a{sa{sv}}oo",
                args=(connection, self._device_path, "/"),
            )
        except Exception as exc:  # noqa: BLE001
            self._emit_failure(name, str(exc))

    # ── internals ─────────────────────────────────────────────────────────
    def _props(self, interface: str, path: str) -> dict:
        result = self._bus.call(
            destination=NM,
            path=path,
            interface=PROPS,
            member="GetAll",
            signature="s",
            args=(interface,),
        )
        return result if isinstance(result, dict) else {}

    def _refresh_all(self) -> None:
        devices = self._bus.call(destination=NM, path=NM_PATH, interface=NM, member="GetDevices")
        self._known_ssids = self._list_known_ssids()
        wifi = ""
        for device_path in devices or ():
            props = self._props(DEV_IFACE, device_path)
            if props.get("DeviceType") == DEVICE_TYPE_WIFI:
                wifi = device_path
                break
        self._device_path = wifi
        if not wifi:
            self.notify(Network(available=False))
            return
        self._refresh_aps()

    def _list_known_ssids(self) -> set[str]:
        try:
            connections = self._bus.call(
                destination=NM,
                path="/org/freedesktop/NetworkManager/Settings",
                interface=SETTINGS,
                member="ListConnections",
            )
        except Exception:  # noqa: BLE001
            return set()
        ssids: set[str] = set()
        for conn_path in connections or ():
            try:
                settings = self._bus.call(
                    destination=NM,
                    path=str(conn_path),
                    interface="org.freedesktop.NetworkManager.Settings.Connection",
                    member="GetSettings",
                )
            except Exception:  # noqa: BLE001
                continue
            wireless = settings.get("802-11-wireless") or {}
            ssid = wireless.get("ssid")
            if isinstance(ssid, bytes):
                ssids.add(ssid_bytes_to_text(ssid))
        return ssids

    def _existing_connection(self, name: str) -> str:
        try:
            connections = self._bus.call(
                destination=NM,
                path="/org/freedesktop/NetworkManager/Settings",
                interface=SETTINGS,
                member="ListConnections",
            )
        except Exception:  # noqa: BLE001
            return ""
        for conn_path in connections or ():
            try:
                settings = self._bus.call(
                    destination=NM,
                    path=str(conn_path),
                    interface="org.freedesktop.NetworkManager.Settings.Connection",
                    member="GetSettings",
                )
            except Exception:  # noqa: BLE001
                continue
            wireless = settings.get("802-11-wireless") or {}
            if ssid_bytes_to_text(wireless.get("ssid")) == name:
                return str(conn_path)
        return ""

    def _refresh_aps(self) -> None:
        if not self._device_path:
            return
        try:
            wired = self._props(NM, NM_PATH)
            wifi_enabled = bool(wired.get("WirelessEnabled", False))
        except Exception:  # noqa: BLE001
            wifi_enabled = False
        try:
            device = self._props(WIFI_IFACE, self._device_path)
        except Exception as exc:  # noqa: BLE001
            self._warn("wifi device read failed", error=str(exc))
            return
        active_path = device.get("ActiveAccessPoint") or ""
        raw: list[tuple[str, float, bool, bool, bool]] = []
        active_ssid = ""
        for ap_path in device.get("AccessPoints", []) or ():
            try:
                ap = self._props(AP_IFACE, ap_path)
            except Exception:  # noqa: BLE001
                continue
            ssid = ssid_bytes_to_text(ap.get("Ssid"))
            if not ssid:
                continue
            strength = float(ap.get("Strength") or 0) / 100.0
            secured = secured_from_flags(ap.get("WpaFlags"), ap.get("RsnFlags"))
            connected = bool(active_path) and str(ap_path) == str(active_path)
            if connected:
                active_ssid = ssid
            raw.append((ssid, strength, secured, ssid in self._known_ssids, connected))
        entries = dedupe_networks(raw)
        active = next((e for e in entries if e.connected), None)
        self.notify(
            Network(
                available=True,
                wifi_enabled=wifi_enabled,
                connected=active is not None,
                ssid=active.name if active else active_ssid,
                strength=(active.signal / 100.0) if active else 0.0,
                scanning=self._scanning,
                networks=tuple(entries),
            )
        )
        if self._scanning:
            self.request_scan()

    def _on_device_change(self, *_args) -> None:
        if self._device_path:
            self._refresh_aps()

    def _emit_failure(self, name: str, reason: str) -> None:
        self._warn("connection failed", name=name, reason=reason)
        for listener in tuple(self._failure_listeners):
            listener(name, reason)

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("network", message, **context)
