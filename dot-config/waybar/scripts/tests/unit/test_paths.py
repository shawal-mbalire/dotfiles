import os

from infra import paths


def test_cache_dir_uses_runtime_dir(monkeypatch):
    monkeypatch.setenv("XDG_RUNTIME_DIR", "/run/user/4242")
    expected = os.path.join("/run/user/4242", f"waybar-cache-{os.getuid()}")
    assert paths.cache_dir() == expected


def test_cache_dir_falls_back_when_unset(monkeypatch):
    monkeypatch.delenv("XDG_RUNTIME_DIR", raising=False)
    assert paths.cache_dir() == os.path.join("/tmp", f"waybar-cache-{os.getuid()}")


def test_cache_dir_treats_empty_runtime_dir_as_unset(monkeypatch):
    monkeypatch.setenv("XDG_RUNTIME_DIR", "")
    assert paths.runtime_dir() == "/tmp"
