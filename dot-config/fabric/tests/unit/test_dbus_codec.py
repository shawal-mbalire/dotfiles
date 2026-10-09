"""D-Bus codec round-trip tests — prove the wire format without a bus."""

from __future__ import annotations

from adapters.driven.dbus.codec import Variant, marshal, unmarshal
from adapters.driven.dbus.message import build_method_call, parse


def roundtrip(signature: str, value):
    data = marshal(signature, value)
    result, offset = unmarshal(signature, data)
    assert offset == len(data) or offset <= len(data)
    return result


def test_basic_ints():
    assert roundtrip("y", 200) == 200
    assert roundtrip("n", -5) == -5
    assert roundtrip("q", 65535) == 65535
    assert roundtrip("i", -123456) == -123456
    assert roundtrip("u", 4000000000) == 4000000000
    assert roundtrip("x", -(2**40)) == -(2**40)
    assert roundtrip("t", 2**40) == 2**40


def test_boolean_double():
    assert roundtrip("b", True) is True
    assert roundtrip("b", False) is False
    assert roundtrip("d", 3.5) == 3.5


def test_strings_paths_signatures():
    assert roundtrip("s", "hello world") == "hello world"
    assert roundtrip("o", "/org/example/Path") == "/org/example/Path"
    assert roundtrip("g", "a{sv}") == "a{sv}"


def test_arrays():
    assert roundtrip("as", ["a", "bb", "ccc"]) == ["a", "bb", "ccc"]
    assert roundtrip("au", [1, 2, 3]) == [1, 2, 3]
    assert roundtrip("ay", b"\x01\x02\x03") == b"\x01\x02\x03"


def test_structs_and_dicts():
    assert roundtrip("(su)", ("name", 7)) == ("name", 7)
    data = marshal("a{sv}", {"key": Variant("s", "value"), "num": Variant("u", 5)})
    result, _ = unmarshal("a{sv}", data)
    assert result == {"key": "value", "num": 5}


def test_variant_nesting():
    data = marshal("v", Variant("s", "hi"))
    result, _ = unmarshal("v", data)
    assert isinstance(result, Variant)
    assert result.signature == "s" and result.value == "hi"


def test_message_header_roundtrip():
    raw = build_method_call(
        destination="org.freedesktop.DBus",
        path="/org/freedesktop/DBus",
        interface="org.freedesktop.DBus",
        member="RequestName",
        signature="su",
        args=("org.example.Name", 0),
        serial=3,
    )
    parsed = parse(raw)
    assert parsed.message.type == 1
    assert parsed.message.serial == 3
    assert parsed.message.path == "/org/freedesktop/DBus"
    assert parsed.message.interface == "org.freedesktop.DBus"
    assert parsed.message.member == "RequestName"
    assert parsed.message.destination == "org.freedesktop.DBus"
    assert parsed.message.signature == "su"
    assert parsed.body == ("org.example.Name", 0)


def test_message_header_no_body():
    raw = build_method_call(
        destination="org.freedesktop.DBus",
        path="/org/freedesktop/DBus",
        interface="org.freedesktop.DBus",
        member="Hello",
        serial=1,
    )
    parsed = parse(raw)
    assert parsed.message.member == "Hello"
    assert parsed.message.signature == ""
