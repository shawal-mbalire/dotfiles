"""WorkspacePort — Hyprland workspaces."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import WorkspaceState
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class WorkspacePort(ObservablePort[WorkspaceState], Protocol):
    """CONTRACT — WorkspacePort.

    ``read()`` → WorkspaceState(workspaces sorted by id, focused_id, count).

    Commands:
      focus(id)  switch to workspace *id*.
    """

    def read(self) -> WorkspaceState: ...

    def subscribe(self, listener: Listener[WorkspaceState]) -> Unsubscribe: ...

    def focus(self, workspace_id: int) -> None: ...
