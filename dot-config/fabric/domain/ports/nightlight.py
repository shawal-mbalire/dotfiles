"""NightLightPort — colour-temperature shift (e.g. Hyprsunset)."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import NightLight
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class NightLightPort(ObservablePort[NightLight], Protocol):
    """CONTRACT — NightLightPort.

    ``read()`` → NightLight(active).

    Commands:
      set_active(active)
        Post: active == active immediately, re-verified against the system soon.
      refresh()
        Re-read external state (it can change outside the shell).
    """

    def read(self) -> NightLight: ...

    def subscribe(self, listener: Listener[NightLight]) -> Unsubscribe: ...

    def set_active(self, active: bool) -> None: ...

    def refresh(self) -> None: ...
