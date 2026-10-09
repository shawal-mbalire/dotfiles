"""Hyprland driven adapters: workspaces, wallpaper, night light."""

from __future__ import annotations

from adapters.driven.hyprland.ipc import HyprlandIpc, HyprlandIpcError
from adapters.driven.hyprland.workspaces import HyprlandWorkspaceAdapter

__all__ = ["HyprlandIpc", "HyprlandIpcError", "HyprlandWorkspaceAdapter"]
