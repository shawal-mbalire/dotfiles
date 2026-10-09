"""BluetoothPort — adapter power and the first connected device."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Bluetooth
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class BluetoothPort(ObservablePort[Bluetooth], Protocol):
    """CONTRACT — BluetoothPort.

    ``read()`` → Bluetooth(available, enabled, connected_name).
    Connectedness is ``connected_name != ""``.

    Commands:
      set_enabled(enabled)
        Post: enabled follows once BlueZ reports; logged no-op when !available.
    """

    def read(self) -> Bluetooth: ...

    def subscribe(self, listener: Listener[Bluetooth]) -> Unsubscribe: ...

    def set_enabled(self, enabled: bool) -> None: ...
