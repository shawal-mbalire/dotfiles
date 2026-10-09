"""D-Bus transport — a minimal native client over the session/system bus.

Connects the Unix socket, performs EXTERNAL authentication, and runs a reader
thread that dispatches method returns, signals, and incoming method calls.
Standard library only.
"""

from __future__ import annotations

import contextlib
import os
import socket
import struct
import threading
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from adapters.driven.dbus import message as M
from adapters.driven.dbus.codec import Variant
from adapters.driven.dbus.message import DBusError, Message, build_method_call, parse

MethodCallHandler = Callable[["IncomingCall"], None]
SignalHandler = Callable[[str, str, str, object], None]


@dataclass(slots=True)
class IncomingCall:
    """A method call we must answer (e.g. a notification client calling us)."""

    message: Message
    body: object
    _connection: BusConnection

    def reply(self, signature: str = "", args: tuple = ()) -> None:
        self._connection.send_method_return(self.message, signature, args)

    def reply_error(self, name: str, text: str) -> None:
        self._connection.send_error(self.message, name, text)


def session_address() -> str:
    address = os.environ.get("DBUS_SESSION_BUS_ADDRESS", "")
    if address:
        return address
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    return f"unix:path={runtime}/bus"


def system_address() -> str:
    return os.environ.get("DBUS_SYSTEM_BUS_ADDRESS", "unix:path=/run/dbus/system_bus_socket")


def _parse_address(address: str) -> tuple[int, str, str]:
    """Return (family, kind, value) for a unix: D-Bus address."""
    for part in address.split(";"):
        if not part.startswith("unix:"):
            continue
        options = dict(
            item.split("=", 1) for item in part[len("unix:") :].split(",") if "=" in item
        )
        if "abstract" in options:
            return socket.AF_UNIX, "abstract", options["abstract"]
        if "path" in options:
            return socket.AF_UNIX, "path", options["path"]
    raise DBusError("org.freedesktop.DBus.Error.BadAddress", f"unsupported address {address!r}")


def _recv_exact(sock: socket.socket, count: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < count:
        chunk = sock.recv(count - len(chunks))
        if not chunk:
            raise ConnectionError("D-Bus connection closed")
        chunks.extend(chunk)
    return bytes(chunks)


def _readline(sock: socket.socket) -> bytes:
    line = bytearray()
    while not line.endswith(b"\r\n"):
        byte = sock.recv(1)
        if not byte:
            raise ConnectionError("D-Bus closed during authentication")
        line.extend(byte)
    return bytes(line)


class BusConnection:
    """A synchronous D-Bus connection with a background reader thread."""

    def __init__(self, address: str | None = None, name: str = "fabric") -> None:
        self._address = address or session_address()
        self._name = name
        self._sock: socket.socket | None = None
        self._serial = 0
        self._lock = threading.RLock()
        self._pending: dict[int, tuple[threading.Event, dict[str, Any]]] = {}
        self._signal_handlers: list[tuple[str, str, SignalHandler]] = []
        self._call_handlers: list[tuple[str, str, MethodCallHandler]] = []
        self._reader: threading.Thread | None = None
        self._closed = threading.Event()
        self.unique_name = ""

    # ── connection lifecycle ──────────────────────────────────────────────
    def connect(self) -> None:
        family, kind, value = _parse_address(self._address)
        sock = socket.socket(family, socket.SOCK_STREAM)
        if kind == "abstract":
            sock.connect("\0" + value)
        else:
            sock.connect(value)
        self._sock = sock
        self._authenticate()
        self._reader = threading.Thread(
            target=self._read_loop, daemon=True, name=f"fabric-dbus-{self._name}"
        )
        self._reader.start()
        result = self.call(
            destination="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            interface="org.freedesktop.DBus",
            member="Hello",
        )
        self.unique_name = result if isinstance(result, str) else ""

    def _authenticate(self) -> None:
        assert self._sock is not None
        self._sock.sendall(b"\0")
        uid_hex = str(os.getuid()).encode().hex().encode()
        self._sock.sendall(b"AUTH EXTERNAL " + uid_hex + b"\r\n")
        response = _readline(self._sock)
        if not response.startswith(b"OK"):
            raise DBusError(
                "org.freedesktop.DBus.Error.AuthFailed", response.decode(errors="replace").strip()
            )
        self._sock.sendall(b"BEGIN\r\n")

    def close(self) -> None:
        self._closed.set()
        if self._sock is not None:
            with contextlib.suppress(OSError):
                self._sock.close()

    # ── sending ───────────────────────────────────────────────────────────
    def _next_serial(self) -> int:
        with self._lock:
            self._serial += 1
            return self._serial

    def _send(self, data: bytes) -> None:
        if self._sock is None:
            raise DBusError("org.freedesktop.DBus.Error.Disconnected", "not connected")
        with self._lock:
            self._sock.sendall(data)

    def call(
        self,
        *,
        destination: str,
        path: str,
        interface: str,
        member: str,
        signature: str = "",
        args: tuple = (),
        timeout: float = 20.0,
    ) -> Any:
        serial = self._next_serial()
        event = threading.Event()
        holder: dict[str, Any] = {}
        self._pending[serial] = (event, holder)
        data = build_method_call(
            destination=destination,
            path=path,
            interface=interface,
            member=member,
            signature=signature,
            args=args,
            serial=serial,
        )
        try:
            self._send(data)
        except OSError as exc:
            self._pending.pop(serial, None)
            raise DBusError("org.freedesktop.DBus.Error.Disconnected", str(exc)) from exc
        if not event.wait(timeout):
            self._pending.pop(serial, None)
            raise DBusError("org.freedesktop.DBus.Error.Timeout", f"{interface}.{member} timed out")
        if "error" in holder:
            raise holder["error"]
        return holder.get("value", tuple())

    def send_method_return(self, call: Message, signature: str = "", args: tuple = ()) -> None:
        from adapters.driven.dbus.codec import marshal

        body = marshal(signature, *args) if signature else b""
        reply = Message(
            type=M.METHOD_RETURN,
            serial=self._next_serial(),
            reply_serial=call.serial,
            destination=call.sender,
            signature=signature,
        )
        self._send(reply.marshalled(body))

    def send_error(self, call: Message, name: str, text: str) -> None:
        from adapters.driven.dbus.codec import marshal

        body = marshal("s", text)
        reply = Message(
            type=M.ERROR,
            serial=self._next_serial(),
            error_name=name,
            reply_serial=call.serial,
            destination=call.sender,
            signature="s",
        )
        self._send(reply.marshalled(body))

    def emit_signal(
        self,
        *,
        path: str,
        interface: str,
        member: str,
        signature: str = "",
        args: tuple = (),
    ) -> None:
        from adapters.driven.dbus.codec import marshal

        body = marshal(signature, *args) if signature else b""
        signal = Message(
            type=M.SIGNAL,
            serial=self._next_serial(),
            path=path,
            interface=interface,
            member=member,
            signature=signature,
        )
        self._send(signal.marshalled(body))

    # ── handlers ──────────────────────────────────────────────────────────
    def add_match(self, rule: str) -> None:
        self.call(
            destination="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            interface="org.freedesktop.DBus",
            member="AddMatch",
            signature="s",
            args=(rule,),
        )

    def request_name(self, name: str, flags: int = 0) -> int:
        result = self.call(
            destination="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            interface="org.freedesktop.DBus",
            member="RequestName",
            signature="su",
            args=(name, flags),
        )
        return int(result)

    def on_signal(self, interface: str, member: str, handler: SignalHandler) -> None:
        self._signal_handlers.append((interface, member, handler))

    def on_method_call(self, interface: str, member: str, handler: MethodCallHandler) -> None:
        self._call_handlers.append((interface, member, handler))

    # ── reader ────────────────────────────────────────────────────────────
    def _read_loop(self) -> None:
        assert self._sock is not None
        try:
            while not self._closed.is_set():
                data = self._read_one_message(self._sock)
                parsed = parse(data)
                self._dispatch(parsed.message, parsed.body)
        except (OSError, ConnectionError, ValueError):
            self._closed.set()
            for event, _holder in tuple(self._pending.values()):
                event.set()

    def _read_one_message(self, sock: socket.socket) -> bytes:
        fixed = _recv_exact(sock, 12)
        body_length = struct.unpack_from("<I", fixed, 4)[0]
        head = _recv_exact(sock, 4)
        array_length = struct.unpack_from("<I", head, 0)[0]
        fields = _recv_exact(sock, array_length)
        offset = 16 + array_length
        padding = (-offset) % 8
        pad = _recv_exact(sock, padding) if padding else b""
        body = _recv_exact(sock, body_length) if body_length else b""
        return fixed + head + fields + pad + body

    def _dispatch(self, message: Message, body: object) -> None:
        if message.type in (M.METHOD_RETURN, M.ERROR):
            entry = self._pending.pop(message.reply_serial, None)
            if entry is None:
                return
            event, holder = entry
            if message.type == M.ERROR:
                text = body if isinstance(body, str) else str(body)
                holder["error"] = DBusError(message.error_name, text)
            else:
                holder["value"] = body
            event.set()
            return
        if message.type == M.SIGNAL:
            for interface, member, handler in self._signal_handlers:
                if (interface in ("", message.interface)) and (member in ("", message.member)):
                    handler(message.path, message.interface, message.member, body)
            return
        if message.type == M.METHOD_CALL:
            for call_interface, call_member, call_handler in self._call_handlers:
                if (call_interface in ("", message.interface)) and (
                    call_member in ("", message.member)
                ):
                    call_handler(IncomingCall(message, body, self))
                    return
            self.send_error(
                message,
                "org.freedesktop.DBus.Error.UnknownMethod",
                f"{message.interface}.{message.member} is not implemented",
            )


def variant_value(value: object) -> object:
    """Unwrap a Variant if present (used when reading property dictionaries)."""
    return value.value if isinstance(value, Variant) else value
