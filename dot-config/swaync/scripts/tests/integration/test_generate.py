"""Integration: run the real composition root into a temporary output dir.

Proves config + adapters + domain wire up end to end and that ``check`` detects
drift, without touching the tracked artifacts.
"""

import json

import main


def test_generate_then_check_is_clean(tmp_path, monkeypatch):
    monkeypatch.setenv("SWAYNC_OUTPUT_DIR", str(tmp_path))

    assert main.cmd_generate([]) == 0
    assert (tmp_path / "config.json").exists()
    assert (tmp_path / "style.css").exists()

    payload = json.loads((tmp_path / "config.json").read_text(encoding="utf-8"))
    assert len(payload["widgets"]) == 6

    assert main.cmd_check([]) == 0


def test_check_detects_stale_artifact(tmp_path, monkeypatch):
    monkeypatch.setenv("SWAYNC_OUTPUT_DIR", str(tmp_path))
    main.cmd_generate([])

    (tmp_path / "style.css").write_text("/* stale */\n", encoding="utf-8")
    assert main.cmd_check([]) == 1


def test_reload_command_runs_via_runner(tmp_path, monkeypatch):
    monkeypatch.setenv("SWAYNC_OUTPUT_DIR", str(tmp_path))
    monkeypatch.setenv("SWAYNC_RELOAD", "true")

    assert main.cmd_reload([]) == 0
