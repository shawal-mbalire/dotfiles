"""NetworkPort — Wi-Fi radio, active link, and scanned networks."""

from __future__ import annotations

from collections.abc import Callable
from typing import Protocol, runtime_checkable

from domain.models import Network
from domain.ports.base import Listener, ObservablePort, Unsubscribe

FailureListener = Callable[[str, str], None]  # (name, reason)


@runtime_checkable
class NetworkPort(ObservablePort[Network], Protocol):
    """CONTRACT — NetworkPort (Wi-Fi).

    ``read()`` → Network(wifi_enabled, connected, ssid, strength 0..1, scanning,
    networks). ``networks`` is unique by name, connected first, then by signal.

    Commands:
      set_wifi_enabled(enabled)   Post: follows once the backend reports.
      set_scanning(scanning)      Post: ``networks`` stays live while true.
      connect_to(name)            Pre: name ∈ networks. Post: connected/ssid on
                                  success, else exactly one failure event.
      connect_with_psk(name, psk) Pre: as connect_to, psk non-empty.
      subscribe_failures(fn)      Receive (name, reason); reason == "NoSecrets"
                                  means a password is required.
    """

    def read(self) -> Network: ...

    def subscribe(self, listener: Listener[Network]) -> Unsubscribe: ...

    def subscribe_failures(self, listener: FailureListener) -> Unsubscribe: ...

    def set_wifi_enabled(self, enabled: bool) -> None: ...

    def set_scanning(self, scanning: bool) -> None: ...

    def connect_to(self, name: str) -> None: ...

    def connect_with_psk(self, name: str, psk: str) -> None: ...
