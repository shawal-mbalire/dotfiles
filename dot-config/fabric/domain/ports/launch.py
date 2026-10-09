"""LaunchPort — installed applications."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import AppEntry
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class LaunchPort(ObservablePort[tuple[AppEntry, ...]], Protocol):
    """CONTRACT — LaunchPort.

    ``read()`` → apps sorted by name; every entry has a non-empty id and name;
    ``icon_source`` is a ready-to-use Image source or "".

    Commands:
      launch(id) -> bool
        Pre:  id ∈ apps.
        Post: True and the app started detached, or False (logged) for unknown id.
    """

    def read(self) -> tuple[AppEntry, ...]: ...

    def subscribe(self, listener: Listener[tuple[AppEntry, ...]]) -> Unsubscribe: ...

    def launch(self, app_id: str) -> bool: ...
