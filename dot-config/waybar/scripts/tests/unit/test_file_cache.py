import json

from adapters.file_cache import FileCache
from domain.workflows.cache import is_stale

from tests.fixtures.fakes import FakeTime


def _cache(tmp_path, now_ms: int = 1_000) -> FileCache:
    return FileCache(str(tmp_path), FakeTime(now_ms=now_ms))


def test_write_then_read_roundtrip(tmp_path):
    cache = _cache(tmp_path)
    cache.write("pill-clock", '{"text": "x"}', 1000)
    payload, age_ms, ttl_ms = cache.read("pill-clock")
    assert payload == '{"text": "x"}'
    assert ttl_ms == 1000
    assert age_ms == 0


def test_age_tracks_injected_clock(tmp_path):
    time = FakeTime(now_ms=1_000)
    cache = FileCache(str(tmp_path), time)
    cache.write("pill-clock", "body", 1000)

    time.advance(750)

    _, age_ms, _ = cache.read("pill-clock")
    assert age_ms == 750


def test_read_missing_returns_none(tmp_path):
    payload, age_ms, ttl_ms = _cache(tmp_path).read("nope")
    assert payload is None
    assert age_ms == -1 and ttl_ms == -1


def test_read_corrupt_header_still_returns_payload(tmp_path):
    (tmp_path / "broken.json").write_text("not-a-header\nbody", encoding="utf-8")
    payload, age_ms, ttl_ms = _cache(tmp_path).read("broken")
    assert payload == "body"
    assert ttl_ms == -1


def test_write_is_atomic_and_valid_json(tmp_path):
    _cache(tmp_path).write("power-status", '{"text": "Balanced"}', 100)
    payload, _, _ = _cache(tmp_path).read("power-status")
    assert json.loads(payload)["text"] == "Balanced"
    assert not list(tmp_path.glob("*.tmp"))


def test_is_stale():
    assert is_stale(age_ms=2000, ttl_ms=1000) is True
    assert is_stale(age_ms=500, ttl_ms=1000) is False
    assert is_stale(age_ms=9999, ttl_ms=-1) is False
