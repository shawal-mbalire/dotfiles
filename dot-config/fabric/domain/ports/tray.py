"""TrayPort — StatusNotifierItem system tray."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import TrayItem
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class TrayPort(ObservablePort[tuple[TrayItem, ...]], Protocol):
    """CONTRACT — TrayPort.

    ``read()`` → registered StatusNotifierItems (already filtered by policy).

    Commands:
      activate(id)            primary activation (left click).
      secondary_activate(id)  secondary activation (middle click).
      context_menu(id)        ask the host to open the item's menu.
    """

    def read(self) -> tuple[TrayItem, ...]: ...

    def subscribe(self, listener: Listener[tuple[TrayItem, ...]]) -> Unsubscribe: ...

    def activate(self, item_id: str) -> None: ...

    def secondary_activate(self, item_id: str) -> None: ...

    def context_menu(self, item_id: str) -> None: ...
