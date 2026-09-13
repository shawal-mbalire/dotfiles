"""End-to-end tests: drive the real entry point as waybar would.

Each test runs ``main.py`` in a subprocess with an isolated ``XDG_RUNTIME_DIR``
so the composition root, cache, and CLI are exercised as a whole — no fakes.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[2]
MAIN = SCRIPTS / "main.py"


def _run(args: list[str], runtime_dir: Path, **env_overrides: str) -> subprocess.CompletedProcess:
    env = {**os.environ, "XDG_RUNTIME_DIR": str(runtime_dir)}
    env.update(env_overrides)
    return subprocess.run(
        [sys.executable, "-S", str(MAIN), *args],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )


def test_pill_prints_seeded_cache(tmp_path, monkeypatch):
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path))

    from adapters.file_cache import FileCache
    from adapters.system_time import SystemTime
    from domain.constants import MODULE_TTL_MS
    from infra.paths import cache_dir

    directory = cache_dir()
    os.makedirs(directory, exist_ok=True)
    FileCache(directory, SystemTime()).write(
        "pill-clock", '{"text": "CACHED", "tooltip": ""}', MODULE_TTL_MS["pill-clock"]
    )

    result = _run(["pill", "clock"], tmp_path)

    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["text"] == "CACHED"


def test_refresh_writes_every_module(tmp_path, monkeypatch):
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path))

    from domain.constants import MODULE_TTL_MS
    from infra.paths import cache_dir

    # Empty PATH: optional external commands are unavailable, so the refresh
    # must degrade gracefully and still render every module from sysfs/proc.
    result = _run(["refresh"], tmp_path, PATH=str(tmp_path))

    assert result.returncode == 0, result.stderr
    written = {path.stem for path in Path(cache_dir()).glob("*.json")}
    assert written == set(MODULE_TTL_MS), f"missing: {set(MODULE_TTL_MS) - written}"


def test_unknown_command_fails(tmp_path):
    result = _run(["definitely-not-a-command"], tmp_path)

    assert result.returncode == 1
    assert "Unknown command" in result.stderr


def test_help_lists_commands(tmp_path):
    result = _run(["--help"], tmp_path)

    assert result.returncode == 0
    assert "main.py pill" in result.stdout
