"""HyprlandWorkspaceAdapter — WorkspacePort over native Hyprland IPC."""

from __future__ import annotations

import threading
from pathlib import Path

from adapters.driven.hyprland.ipc import (
    RELEVANT_EVENTS,
    HyprlandIpc,
    HyprlandIpcError,
    focus_command,
    parse_active_id,
    parse_workspace_ids,
)
from adapters.driven.observable import Observable
from domain.models import Workspace, WorkspaceState


class HyprlandWorkspaceAdapter(Observable[WorkspaceState]):
    """Observes workspaces via the event socket; dispatches focus via the
    request socket. Degrades to an empty state (logged) when not on Hyprland.
    """

    def __init__(
        self,
        socket_path: Path,
        *,
        count: int = 10,
        using_lua: bool = False,
        logger=None,
    ) -> None:
        super().__init__(WorkspaceState(count=count))
        self._ipc = HyprlandIpc(socket_path)
        self._count = count
        self._using_lua = using_lua
        self._logger = logger
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._refresh()

    # ── commands ──────────────────────────────────────────────────────────
    def focus(self, workspace_id: int) -> None:
        try:
            self._ipc.request(focus_command(workspace_id, self._using_lua))
        except HyprlandIpcError as exc:
            self._warn("focus failed", error=str(exc), workspace=workspace_id)

    # ── start ─────────────────────────────────────────────────────────────
    def start(self) -> None:
        if self._thread is not None:
            return
        if not self._ipc.socket_path.exists() or not self._ipc.socket_path.name:
            self._warn("no Hyprland socket available; workspaces stay empty")
            return
        self._thread = threading.Thread(target=self._listen, daemon=True, name="fabric-hypr-events")
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    # ── internals ─────────────────────────────────────────────────────────
    def _refresh(self) -> None:
        try:
            ids = parse_workspace_ids(self._ipc.request_json("workspaces"))
            focused = parse_active_id(self._ipc.request_json("activeworkspace"))
        except HyprlandIpcError as exc:
            self._warn("refresh failed", error=str(exc))
            return
        state = WorkspaceState(
            workspaces=tuple(Workspace(id=wid, active=wid == focused) for wid in ids),
            focused_id=focused,
            count=self._count,
        )
        self.notify(state)

    def _listen(self) -> None:
        backoff = 1.0
        while not self._stop.is_set():
            try:
                for event, _data in self._ipc.events():
                    if self._stop.is_set():
                        return
                    if event in RELEVANT_EVENTS:
                        self._refresh()
                    backoff = 1.0
            except HyprlandIpcError:
                if self._stop.wait(backoff):
                    return
                backoff = min(backoff * 2, 30.0)

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("hyprland", message, **context)
