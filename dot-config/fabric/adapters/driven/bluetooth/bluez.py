"""BluezAdapter — BluetoothPort over the BlueZ D-Bus API.

Service  org.bluez
Object   /  implements org.freedesktop.DBus.ObjectManager
Adapters /org/bluez/hciN  → org.bluez.Adapter1 (Powered)
Devices  /org/bluez/hciN/… → org.bluez.Device1 (Connected, Alias)
No bluetoothctl.
"""

from __future__ import annotations

import contextlib

from adapters.driven.dbus import BusConnection, Variant
from adapters.driven.observable import Observable
from domain.models import Bluetooth

BLUEZ = "org.bluez"
BLUEZ_PATH = "/"
ADAPTER1 = "org.bluez.Adapter1"
DEVICE1 = "org.bluez.Device1"
OM = "org.freedesktop.DBus.ObjectManager"
PROPS = "org.freedesktop.DBus.Properties"


def _first_adapter(objects: dict) -> tuple[str, dict] | None:
    for path, interfaces in objects.items():
        if ADAPTER1 in interfaces:
            return path, interfaces[ADAPTER1]
    return None


class BluezAdapter(Observable[Bluetooth]):
    def __init__(self, bus: BusConnection, *, logger=None) -> None:
        super().__init__(Bluetooth(available=False))
        self._bus = bus
        self._logger = logger
        self._adapter_path = ""
        self._bus.on_signal(BLUEZ, "PropertiesChanged", self._on_properties_changed)
        self._bus.on_signal(OM, "InterfacesAdded", self._on_properties_changed)
        self._bus.on_signal(OM, "InterfacesRemoved", self._on_properties_changed)

    def start(self) -> None:
        try:
            self.refresh()
        except Exception as exc:  # noqa: BLE001
            self._warn("initial refresh failed", error=str(exc))
            self.notify(Bluetooth(available=False))

    # ── commands ──────────────────────────────────────────────────────────
    def set_enabled(self, enabled: bool) -> None:
        if not self._adapter_path:
            self._warn("no bluetooth adapter; ignoring toggle")
            return
        try:
            self._bus.call(
                destination=BLUEZ,
                path=self._adapter_path,
                interface=PROPS,
                member="Set",
                signature="ssv",
                args=(ADAPTER1, "Powered", Variant("b", enabled)),
            )
        except Exception as exc:  # noqa: BLE001
            self._warn("set powered failed", error=str(exc))

    # ── internals ─────────────────────────────────────────────────────────
    def refresh(self) -> None:
        result = self._bus.call(
            destination=BLUEZ, path=BLUEZ_PATH, interface=OM, member="GetManagedObjects"
        )
        objects = result if isinstance(result, dict) else {}
        adapter = _first_adapter(objects)
        if adapter is None:
            self.notify(Bluetooth(available=False))
            self._adapter_path = ""
            return
        adapter_path, adapter_props = adapter
        self._adapter_path = adapter_path
        enabled = bool(adapter_props.get("Powered", False))
        connected_name = ""
        for _path, interfaces in objects.items():
            device = interfaces.get(DEVICE1) or {}
            if device.get("Connected") and not connected_name:
                connected_name = str(device.get("Alias") or device.get("Name") or "")
        self.notify(Bluetooth(available=True, enabled=enabled, connected_name=connected_name))

    def _on_properties_changed(self, *_args) -> None:
        with contextlib.suppress(Exception):
            self.refresh()

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("bluetooth", message, **context)
