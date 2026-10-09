"""A control socket for IPC — Hyprland keybinds talk to the running shell.

Native Unix socket; no shell scripts. Commands are ``verb target`` lines, e.g.
``toggle bar`` or ``wallpaper next``.
"""

from __future__ import annotations

import contextlib
import socketserver
import threading
from collections.abc import Callable
from pathlib import Path

Handler = Callable[[], None]


class _Server(socketserver.ThreadingUnixStreamServer):
    daemon_threads = True
    allow_reuse_address = True


class _RequestHandler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        line = self.rfile.readline().decode(errors="replace").strip()
        if not line:
            return
        self.server.actions.handle(line, self)  # type: ignore[attr-defined]


class _Actions:
    def __init__(self, handlers: dict[str, Handler]) -> None:
        self._handlers = handlers

    def handle(self, line: str, request: _RequestHandler) -> None:
        handler = self._handlers.get(line)
        if handler is None:
            request.wfile.write(b"unknown command\n")
            return
        handler()
        request.wfile.write(b"ok\n")


class ControlSocket:
    """Threaded Unix-socket server dispatching command lines to callbacks."""

    def __init__(self, path: Path, handlers: dict[str, Handler]) -> None:
        self._path = path
        path.parent.mkdir(parents=True, exist_ok=True)
        # Remove a stale socket from a previous run before we bind.
        with contextlib.suppress(OSError):
            path.unlink()
        self._server = _Server(str(path), _RequestHandler)
        self._server.actions = _Actions(handlers)  # type: ignore[attr-defined]
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        self._thread = threading.Thread(
            target=self._server.serve_forever, daemon=True, name="fabric-control"
        )
        self._thread.start()

    def stop(self) -> None:
        self._server.shutdown()
        self._server.server_close()
        with contextlib.suppress(OSError):
            self._path.unlink()


def send_command(path: Path, command: str) -> str:
    """Client side: send a command line and return the reply."""
    import socket

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(str(path))
        sock.sendall((command + "\n").encode())
        return sock.recv(256).decode(errors="replace").strip()
