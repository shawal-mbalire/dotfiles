"""D-Bus messages — header build/parse and the Message value object."""

from __future__ import annotations

import struct
from dataclasses import dataclass, field
from typing import Any, cast

from adapters.driven.dbus.codec import Marshaller, Unmarshaller, Variant, _iter_types, marshal

PROTOCOL_VERSION = 1

# Message types
METHOD_CALL = 1
METHOD_RETURN = 2
ERROR = 3
SIGNAL = 4

# Header field codes
F_PATH = 1
F_INTERFACE = 2
F_MEMBER = 3
F_ERROR_NAME = 4
F_REPLY_SERIAL = 5
F_DESTINATION = 6
F_SENDER = 7
F_SIGNATURE = 8
F_UNIX_FDS = 9

NO_REPLY_EXPECTED = 0x1
NO_AUTO_START = 0x2


class DBusError(Exception):
    def __init__(self, name: str, message: str) -> None:
        super().__init__(f"{name}: {message}")
        self.name = name
        self.message = message


@dataclass(slots=True)
class Message:
    type: int = METHOD_CALL
    serial: int = 0
    flags: int = 0
    path: str = ""
    interface: str = ""
    member: str = ""
    error_name: str = ""
    reply_serial: int = 0
    destination: str = ""
    sender: str = ""
    signature: str = ""
    body: tuple = field(default_factory=tuple)

    def marshalled(self, body: bytes) -> bytes:
        fields: list[tuple[int, Variant]] = []
        if self.path:
            fields.append((F_PATH, Variant("o", self.path)))
        if self.interface:
            fields.append((F_INTERFACE, Variant("s", self.interface)))
        if self.member:
            fields.append((F_MEMBER, Variant("s", self.member)))
        if self.error_name:
            fields.append((F_ERROR_NAME, Variant("s", self.error_name)))
        if self.reply_serial:
            fields.append((F_REPLY_SERIAL, Variant("u", self.reply_serial)))
        if self.destination:
            fields.append((F_DESTINATION, Variant("s", self.destination)))
        if self.sender:
            fields.append((F_SENDER, Variant("s", self.sender)))
        if self.signature:
            fields.append((F_SIGNATURE, Variant("g", self.signature)))
        fields.sort(key=lambda entry: entry[0])

        out = Marshaller()
        out.buffer.extend(b"l")
        out.buffer.extend(bytes([self.type, self.flags, PROTOCOL_VERSION]))
        out.buffer.extend(struct.pack("<I", len(body)))
        out.buffer.extend(struct.pack("<I", self.serial))
        # Header fields: a(yv)
        out.align(4)
        length_pos = len(out.buffer)
        out.buffer.extend(b"\x00\x00\x00\x00")
        out.align(8)
        start = len(out.buffer)
        for code, variant in fields:
            out.align(8)
            out.write("y", code)
            out.write("v", variant)
        struct.pack_into("<I", out.buffer, length_pos, len(out.buffer) - start)
        out.align(8)
        out.buffer.extend(body)
        return bytes(out.buffer)


@dataclass(slots=True)
class ParsedMessage:
    message: Message
    body: object
    body_offset: int


def parse(data: bytes) -> ParsedMessage:
    """Parse a complete message (header + body) from *data*."""
    if len(data) < 12:
        raise ValueError("message too short")
    endian = data[0:1]
    if endian != b"l":
        raise ValueError("only little-endian D-Bus is supported")
    msg_type = data[1]
    flags = data[2]
    body_length = struct.unpack_from("<I", data, 4)[0]
    serial = struct.unpack_from("<I", data, 8)[0]

    unmarshaller = Unmarshaller(data)
    fields, offset = unmarshaller.read("a(yv)", 12)
    message = Message(type=msg_type, serial=serial, flags=flags)
    for item in cast(list, fields):
        code, variant = cast(Any, item[0]), cast(Any, item[1])
        value = variant.value
        if code == F_PATH:
            message.path = value
        elif code == F_INTERFACE:
            message.interface = value
        elif code == F_MEMBER:
            message.member = value
        elif code == F_ERROR_NAME:
            message.error_name = value
        elif code == F_REPLY_SERIAL:
            message.reply_serial = value
        elif code == F_DESTINATION:
            message.destination = value
        elif code == F_SENDER:
            message.sender = value
        elif code == F_SIGNATURE:
            message.signature = value

    body_offset = _align8(offset)
    body = _decode_body(message.signature, data, body_offset, body_length)
    return ParsedMessage(message, body, body_offset)


def _align8(offset: int) -> int:
    remainder = offset % 8
    return offset if remainder == 0 else offset + (8 - remainder)


def _decode_body(signature: str, data: bytes, offset: int, body_length: int) -> object:
    if not signature or body_length == 0:
        return tuple()
    from adapters.driven.dbus.codec import unmarshal

    value, _ = unmarshal(signature, data[offset : offset + body_length], 0)
    if len(list(_iter_types(signature))) == 1:
        return value
    return value


def build_method_call(
    *,
    destination: str,
    path: str,
    interface: str,
    member: str,
    signature: str = "",
    args: tuple = (),
    serial: int,
    flags: int = 0,
) -> bytes:
    body = marshal(signature, *args) if signature else b""
    message = Message(
        type=METHOD_CALL,
        serial=serial,
        flags=flags,
        path=path,
        interface=interface,
        member=member,
        destination=destination,
        signature=signature,
        body=args,
    )
    return message.marshalled(body)
