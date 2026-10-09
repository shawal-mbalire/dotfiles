"""Native adapter tests: Hyprland parsers, sysfs mappings, observable plumbing."""

from __future__ import annotations

from pathlib import Path

from adapters.driven.hyprland.ipc import (
    event_socket_path,
    focus_command,
    parse_active_id,
    parse_event_line,
    parse_workspace_ids,
)
from adapters.driven.observable import Observable
from adapters.driven.sysfs.battery import SysfsBatteryAdapter
from adapters.driven.sysfs.brightness import SysfsBrightnessAdapter
from domain.logic import (
    battery_from_capacity,
    battery_state_text,
    brightness_percent,
    raw_from_percent,
)

# ── Hyprland IPC parsers ───────────────────────────────────────────────────


def test_event_socket_path():
    assert event_socket_path(Path("/run/user/1000/hypr/abc/.socket.sock")) == Path(
        "/run/user/1000/hypr/abc/.socket2.sock"
    )


def test_parse_event_line():
    assert parse_event_line("workspace>>2") == ("workspace", "2")
    assert parse_event_line("no separator") is None


def test_parse_workspace_ids_filters_specials():
    payload = [
        {"id": 1, "name": "1"},
        {"id": -99, "name": "special"},
        {"id": 3, "name": "3"},
        {"id": 1, "name": "dup"},
        "junk",
    ]
    assert parse_workspace_ids(payload) == (1, 3)
    assert parse_workspace_ids("junk") == ()


def test_parse_active_id():
    assert parse_active_id({"id": 4}) == 4
    assert parse_active_id(7) == 7
    assert parse_active_id("bad") == 1


def test_focus_command_branches_on_lua():
    assert focus_command(3) == "dispatch workspace 3"
    assert focus_command(3, using_lua=True) == "dispatch hl.dsp.focus({ workspace = 3 })"


# ── sysfs mappings ─────────────────────────────────────────────────────────


def test_battery_state_text():
    assert battery_state_text("Charging") == "Charging"
    assert battery_state_text("Not charging") == "Plugged in"
    assert battery_state_text("full") == "Full"
    assert battery_state_text("") == "Unknown"


def test_battery_from_capacity():
    reading = battery_from_capacity(True, 62, "Discharging", 600, 0)
    assert reading.level == 62 and reading.charging is False
    assert reading.time_text == "10m left"


def test_brightness_percent_math():
    assert brightness_percent(50, 100) == 50
    assert brightness_percent(0, 0) == 0
    assert raw_from_percent(50, 100) == 50
    assert raw_from_percent(150, 1000) == 1000


def test_sysfs_battery_adapter_reads_files(tmp_path: Path):
    battery_dir = tmp_path / "BAT0"
    battery_dir.mkdir()
    (battery_dir / "present").write_text("1\n")
    (battery_dir / "capacity").write_text("80\n")
    (battery_dir / "status").write_text("Charging\n")
    (battery_dir / "time_to_full_now").write_text("1800\n")
    adapter = SysfsBatteryAdapter(device_dir=battery_dir)
    adapter._produce()
    reading = adapter.read()
    assert reading.present and reading.level == 80 and reading.charging
    assert reading.time_text == "30m to full"


def test_sysfs_brightness_adapter_reads_and_writes(tmp_path: Path):
    device = tmp_path / "intel_backlight"
    device.mkdir()
    (device / "brightness").write_text("500\n")
    (device / "max_brightness").write_text("1000\n")
    written: list[int] = []
    adapter = SysfsBrightnessAdapter(device_dir=device, setter=written.append)
    adapter._produce()
    assert adapter.read() == type(adapter.read())(available=True, percent=50)
    adapter.set_percent(70)
    assert adapter.read().percent == 70
    assert written == [70]


# ── Observable plumbing ────────────────────────────────────────────────────


def test_observable_subscribe_immediate_and_notify():
    source = Observable(1)
    seen: list[int] = []
    unsubscribe = source.subscribe(seen.append)
    assert seen == [1]
    source.notify(2)
    assert seen == [1, 2]
    source.notify(2)  # unchanged → no extra event
    assert seen == [1, 2]
    unsubscribe()
    source.notify(3)
    assert seen == [1, 2]
