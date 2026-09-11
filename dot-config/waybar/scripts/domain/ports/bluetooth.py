"""Bluetooth contracts.

``BluetoothPowerState`` is the fast, poll-safe view (rfkill via sysfs).
``BluetoothGateway`` is the full control surface (bluetoothctl) used by the
interactive menu.
"""

from __future__ import annotations

from typing import Protocol

from domain.models import BluetoothDevice


class BluetoothPowerState(Protocol):
    def is_powered(self) -> bool: ...


class BluetoothGateway(Protocol):
    def is_available(self) -> bool: ...

    def launch_console(self) -> None:
        """Replace the current process with the interactive bluetooth CLI."""
        ...

    def is_powered(self) -> bool: ...

    def set_power(self, on: bool) -> None: ...

    def list_devices(self) -> list[BluetoothDevice]: ...

    def connect(self, mac: str) -> None: ...

    def disconnect(self, mac: str) -> None: ...

    def pair(self, mac: str) -> None: ...

    def trust(self, mac: str) -> None: ...

    def scan(self, seconds: int) -> None: ...
