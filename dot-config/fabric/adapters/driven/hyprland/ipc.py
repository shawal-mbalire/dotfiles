"""Hyprland native IPC — pure Unix-socket client and parsers.

No ``hyprctl`` shell-out. The request socket accepts a command string; the
event socket streams ``event>>data`` lines. Parsers are pure so they can be
unit-tested without a compositor.
"""

from __future__ import annotations

import json
import socket
from collections.abc import Iterator
from pathlib import Path
from typing import Any


class HyprlandIpcError(RuntimeError):
    """Raised when the Hyprland IPC socket cannot be reached or misbehaves."""


def event_socket_path(request_socket: Path) -> Path:
    """Derive the event socket from the request socket path."""
    if not request_socket.name:
        return request_socket
    name = request_socket.name.replace(".socket.sock", ".socket2.sock")
    return request_socket.with_name(name)


class HyprlandIpc:
    """A thin, synchronous client over Hyprland's native IPC sockets."""

    def __init__(self, socket_path: Path, timeout: float = 2.0) -> None:
        self._path = Path(socket_path)
        self._timeout = timeout

    @property
    def socket_path(self) -> Path:
        return self._path

    def available(self) -> bool:
        return self._path.exists()

    def request(self, command: str) -> str:
        """Send a raw command and return the full textual reply."""
        if not self._path.exists():
            raise HyprlandIpcError(f"Hyprland socket not found: {self._path}")
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.settimeout(self._timeout)
                sock.connect(str(self._path))
                sock.sendall(command.encode())
                chunks: list[bytes] = []
                while True:
                    data = sock.recv(65536)
                    if not data:
                        break
                    chunks.append(data)
        except OSError as exc:
            raise HyprlandIpcError(f"Hyprland IPC request failed: {exc}") from exc
        return b"".join(chunks).decode(errors="replace")

    def request_json(self, command: str) -> Any:
        raw = self.request(f"j/{command}")
        try:
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HyprlandIpcError(f"invalid JSON from Hyprland for {command!r}") from exc

    def events(self) -> Iterator[tuple[str, str]]:
        """Yield ``(event, data)`` pairs from the event socket until closed."""
        path = event_socket_path(self._path)
        if not path.exists():
            raise HyprlandIpcError(f"Hyprland event socket not found: {path}")
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.connect(str(path))
            buffer = b""
            while True:
                data = sock.recv(65536)
                if not data:
                    return
                buffer += data
                while b"\n" in buffer:
                    line, buffer = buffer.split(b"\n", 1)
                    parsed = parse_event_line(line.decode(errors="replace"))
                    if parsed is not None:
                        yield parsed


# ── Pure parsers ───────────────────────────────────────────────────────────


def parse_event_line(line: str) -> tuple[str, str] | None:
    if ">>" not in line:
        return None
    event, _, data = line.partition(">>")
    return (event, data)


def parse_workspace_ids(payload: object) -> tuple[int, ...]:
    """Extract positive workspace ids from a ``j/workspaces`` payload."""
    if not isinstance(payload, list):
        return ()
    ids = []
    for item in payload:
        if isinstance(item, dict) and isinstance(item.get("id"), int) and item["id"] > 0:
            ids.append(item["id"])
    return tuple(sorted(set(ids)))


def parse_active_id(payload: object) -> int:
    """Extract the focused workspace id from ``j/activeworkspace``."""
    if isinstance(payload, dict) and isinstance(payload.get("id"), int):
        return payload["id"]
    if isinstance(payload, int):
        return payload
    return 1


def parse_monitors(payload: object) -> tuple[str, ...]:
    if not isinstance(payload, list):
        return ()
    names = []
    for item in payload:
        if isinstance(item, dict) and isinstance(item.get("name"), str):
            names.append(item["name"])
    return tuple(names)


def parse_focused_monitor(payload: object) -> str:
    if isinstance(payload, dict) and isinstance(payload.get("name"), str):
        return payload["name"]
    return ""


def focus_command(workspace_id: int, using_lua: bool = False) -> str:
    """Build the dispatch command to focus a workspace.

    Hyprland in Lua mode needs the Lua form; classic configs take the plain
    ``workspace N`` form.
    """
    if using_lua:
        return f"dispatch hl.dsp.focus({{ workspace = {workspace_id} }})"
    return f"dispatch workspace {workspace_id}"


RELEVANT_EVENTS = frozenset(
    {
        "workspace",
        "workspacev2",
        "focusedmon",
        "focusedmonv2",
        "monitoradded",
        "monitorremoved",
        "openwindow",
        "closewindow",
        "movewindow",
        "createworkspacev2",
        "destroyworkspacev2",
        "activespecial",
    }
)
