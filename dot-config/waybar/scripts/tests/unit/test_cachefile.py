import json

import cachefile


def test_write_then_read_roundtrip(tmp_path):
    cachefile.write(str(tmp_path), "pill-clock", '{"text": "x"}', 1000)
    payload, age_ms, ttl_ms = cachefile.read(str(tmp_path), "pill-clock")
    assert payload == '{"text": "x"}'
    assert ttl_ms == 1000
    assert age_ms >= 0


def test_read_missing_returns_none(tmp_path):
    payload, age_ms, ttl_ms = cachefile.read(str(tmp_path), "nope")
    assert payload is None
    assert age_ms == -1 and ttl_ms == -1


def test_read_corrupt_header_still_returns_payload(tmp_path):
    (tmp_path / "broken.json").write_text("not-a-header\nbody", encoding="utf-8")
    payload, age_ms, ttl_ms = cachefile.read(str(tmp_path), "broken")
    assert payload == "body"
    assert ttl_ms == -1


def test_is_stale():
    assert cachefile.is_stale(age_ms=2000, ttl_ms=1000) is True
    assert cachefile.is_stale(age_ms=500, ttl_ms=1000) is False
    assert cachefile.is_stale(age_ms=9999, ttl_ms=-1) is False


def test_write_is_atomic_and_valid_json(tmp_path):
    cachefile.write(str(tmp_path), "power-status", '{"text": "Balanced"}', 100)
    payload, _, _ = cachefile.read(str(tmp_path), "power-status")
    assert json.loads(payload)["text"] == "Balanced"
    assert not list(tmp_path.glob("*.tmp"))
