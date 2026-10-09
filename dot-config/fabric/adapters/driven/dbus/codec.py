"""D-Bus wire codec — the marshalling rules, implemented on the standard library.

Only little-endian is supported (all Linux desktops of interest are LE). The
codec handles the type codes Fabric needs: y b n q i u x t d s o g a v ( ) { }.
It is pure and unit-tested by round-tripping values.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass
from typing import Any

ALIGNMENT = {
    "y": 1,
    "b": 4,
    "n": 2,
    "q": 2,
    "i": 4,
    "u": 4,
    "x": 8,
    "t": 8,
    "d": 8,
    "s": 4,
    "o": 4,
    "g": 1,
    "a": 4,
    "(": 8,
    "{": 8,
    "v": 1,
}

BASIC = {"y", "b", "n", "q", "i", "u", "x", "t", "d", "s", "o", "g", "h"}
_INT_FMT = {"y": "<B", "n": "<h", "q": "<H", "i": "<i", "u": "<I", "x": "<q", "t": "<Q", "d": "<d"}


@dataclass(frozen=True, slots=True)
class Variant:
    """A D-Bus variant: a signature plus a value of that signature."""

    signature: str
    value: object


def _extent(signature: str, start: int) -> int:
    """Return the index just past the first complete type in *signature*."""
    i = start
    while i < len(signature) and signature[i] == "a":
        i += 1
    if i >= len(signature):
        raise ValueError(f"truncated signature: {signature!r}")
    char = signature[i]
    if char == "(":
        depth = 1
        i += 1
        while i < len(signature) and depth:
            if signature[i] == "(":
                depth += 1
            elif signature[i] == ")":
                depth -= 1
            i += 1
        return i
    if char == "{":
        depth = 1
        i += 1
        while i < len(signature) and depth:
            if signature[i] == "{":
                depth += 1
            elif signature[i] == "}":
                depth -= 1
            i += 1
        return i
    return i + 1


def split_signature(signature: str) -> tuple[str, str]:
    end = _extent(signature, 0)
    return signature[:end], signature[end:]


def _align(offset: int, alignment: int) -> int:
    remainder = offset % alignment
    return offset if remainder == 0 else offset + (alignment - remainder)


class Marshaller:
    """Serialise Python values into D-Bus wire bytes."""

    def __init__(self) -> None:
        self.buffer = bytearray()

    def align(self, alignment: int) -> None:
        target = _align(len(self.buffer), alignment)
        self.buffer.extend(b"\x00" * (target - len(self.buffer)))

    def write(self, signature: str, value: Any) -> None:
        first, rest = split_signature(signature)
        self._write_one(first, value)
        if rest:
            raise ValueError(f"trailing types not written: {rest!r}")

    def _write_one(self, sig: str, value: Any) -> None:
        if sig.startswith("a"):
            self._write_array(sig, value)
            return
        char = sig[0]
        self.align(ALIGNMENT[char])
        if char in _INT_FMT:
            self.buffer.extend(struct.pack(_INT_FMT[char], value))
        elif char == "b":
            self.buffer.extend(struct.pack("<I", 1 if value else 0))
        elif char in ("s", "o"):
            encoded = str(value).encode() + b"\x00"
            self.buffer.extend(struct.pack("<I", len(encoded)))
            self.buffer.extend(encoded)
        elif char == "g":
            encoded = str(value).encode() + b"\x00"
            self.buffer.extend(struct.pack("<B", len(encoded)))
            self.buffer.extend(encoded)
        elif char == "v":
            if not isinstance(value, Variant):
                raise TypeError("variant values must be Variant instances")
            self._write_one("g", value.signature)
            self._write_one(value.signature, value.value)
        elif char == "(":
            self.align(8)
            inner = sig[1:-1]
            for index, field in enumerate(_iter_types(inner)):
                self._write_one(field, value[index])
        elif char == "{":
            self.align(8)
            inner = sig[1:-1]
            key_sig, val_sig = split_signature(inner)
            self._write_one(key_sig, value[0])
            self._write_one(val_sig, value[1])
        else:
            raise ValueError(f"unsupported signature char {char!r}")

    def _write_array(self, sig: str, value: Any) -> None:
        self.align(4)
        length_pos = len(self.buffer)
        self.buffer.extend(b"\x00\x00\x00\x00")
        element_sig = sig[1:]
        element_char = element_sig[0] if element_sig else ""
        self.align(ALIGNMENT.get(element_char, 8))
        start = len(self.buffer)
        if isinstance(value, (bytes, bytearray)) and element_sig == "y":
            self.buffer.extend(value)
        else:
            items = value.items() if isinstance(value, dict) else value
            for item in items:
                self._write_one(element_sig, item)
        length = len(self.buffer) - start
        struct.pack_into("<I", self.buffer, length_pos, length)


def _iter_types(signature: str):
    while signature:
        first, signature = split_signature(signature)
        yield first


def _index_of(signature: str, target: str) -> int:
    for index, entry in enumerate(_iter_types(signature)):
        if entry == target:
            return index
    raise ValueError("struct field not found")


class Unmarshaller:
    """Deserialise D-Bus wire bytes into Python values."""

    def __init__(self, buffer: bytes) -> None:
        self.buffer = buffer

    def align(self, offset: int, alignment: int) -> int:
        return _align(offset, alignment)

    def read(self, signature: str, offset: int) -> tuple[object, int]:
        first, rest = split_signature(signature)
        value, offset = self._read_one(first, offset)
        if rest:
            raise ValueError(f"trailing types not read: {rest!r}")
        return value, offset

    def _read_one(self, sig: str, offset: int) -> tuple[object, int]:
        if sig.startswith("a"):
            return self._read_array(sig, offset)
        char = sig[0]
        offset = self.align(offset, ALIGNMENT[char])
        if char in _INT_FMT:
            value = struct.unpack_from(_INT_FMT[char], self.buffer, offset)[0]
            return value, offset + struct.calcsize(_INT_FMT[char])
        if char == "b":
            value = struct.unpack_from("<I", self.buffer, offset)[0]
            return bool(value), offset + 4
        if char in ("s", "o"):
            length = struct.unpack_from("<I", self.buffer, offset)[0]
            start = offset + 4
            return self.buffer[start : start + length - 1].decode(errors="replace"), start + length
        if char == "g":
            length = struct.unpack_from("<B", self.buffer, offset)[0]
            start = offset + 1
            return self.buffer[start : start + length - 1].decode(), start + length
        if char == "v":
            signature, offset = self._read_one("g", offset)
            value, offset = self._read_one(str(signature), offset)
            return Variant(str(signature), value), offset
        if char == "(":
            offset = self.align(offset, 8)
            inner = sig[1:-1]
            values = []
            for field in _iter_types(inner):
                value, offset = self._read_one(field, offset)
                values.append(value)
            return tuple(values), offset
        if char == "{":
            offset = self.align(offset, 8)
            inner = sig[1:-1]
            key_sig, val_sig = split_signature(inner)
            key, offset = self._read_one(key_sig, offset)
            value, offset = self._read_one(val_sig, offset)
            return (key, value), offset
        raise ValueError(f"unsupported signature char {char!r}")

    def _read_array(self, sig: str, offset: int) -> tuple[object, int]:
        offset = self.align(offset, 4)
        length = struct.unpack_from("<I", self.buffer, offset)[0]
        start = offset + 4
        end = start + length
        element_sig = sig[1:]
        element_char = element_sig[0] if element_sig else ""
        offset = self.align(start, ALIGNMENT.get(element_char, 8))
        if element_sig == "y":
            return bytes(self.buffer[offset:end]), end
        if element_sig.startswith("{"):
            result: dict[object, object] = {}
            while offset < end:
                pair, offset = self._read_one(element_sig, offset)
                if isinstance(pair, tuple) and len(pair) == 2:
                    key, raw = pair[0], pair[1]
                    value: Any = raw.value if isinstance(raw, Variant) else raw
                    result[key] = value
            return result, end
        values: list[object] = []
        while offset < end:
            value, offset = self._read_one(element_sig, offset)
            values.append(value)
        return values, end


def marshal(signature: str, *values: object) -> bytes:
    """Marshal a sequence of values for a body of the given signature."""
    marshaller = Marshaller()
    for sig, value in zip(_iter_types(signature), values, strict=True):
        marshaller.write(sig, value)
    return bytes(marshaller.buffer)


def unmarshal(signature: str, data: bytes, offset: int = 0) -> tuple[object, int]:
    """Unmarshal the body, returning ``(value_or_tuple, new_offset)``."""
    unmarshaller = Unmarshaller(data)
    types = list(_iter_types(signature))
    values: list[object] = []
    for sig in types:
        value, offset = unmarshaller.read(sig, offset)
        values.append(value)
    if len(values) == 1:
        return values[0], offset
    return tuple(values), offset
