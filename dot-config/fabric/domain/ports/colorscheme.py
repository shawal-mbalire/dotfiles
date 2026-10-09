"""ColorSchemePort — the desktop's light/dark preference."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class ColorSchemePort(ObservablePort[bool], Protocol):
    """CONTRACT — ColorSchemePort.

    ``read()`` → True when the desktop prefers dark. Implementations observe the
    preference natively (e.g. GSettings) and push changes to subscribers.

    Commands:
      set_dark(dark)  request the desktop switch; Post: read() follows once the
                      desktop reports back.
    """

    def read(self) -> bool: ...

    def subscribe(self, listener: Listener[bool]) -> Unsubscribe: ...

    def set_dark(self, dark: bool) -> None: ...
