"""Integration tests: exercise real adapters on the host.

Each test skips itself when the underlying source is unavailable, so the suite
still runs on machines without a battery or a running compositor.
"""

from __future__ import annotations

import shutil
from pathlib import Path

import pytest
from domain.models import BatteryStatus, Monitor


def test_sysfs_battery_reads_when_present():
    if not Path("/sys/class/power_supply/BAT0").exists():
        pytest.skip("no BAT0 on this machine")

    from adapters.sysfs_battery import SysfsBattery

    status = SysfsBattery("BAT0").read()
    assert isinstance(status, BatteryStatus)
    assert status.capacity is None or 0 <= status.capacity <= 100


def test_hyprctl_monitors_lists_live_outputs():
    if shutil.which("hyprctl") is None:
        pytest.skip("hyprctl not installed")

    from adapters.hyprctl_monitors import HyprctlMonitors

    try:
        monitors = HyprctlMonitors().list_monitors()
    except Exception:  # noqa: BLE001 - no running compositor in CI
        pytest.skip("no running Hyprland instance")

    assert monitors, "expected at least one monitor"
    assert all(isinstance(monitor, Monitor) for monitor in monitors)


def test_sent_marker_store_claims_once(tmp_path):
    from adapters.sent_marker_store import SentMarkerStore

    store = SentMarkerStore(tmp_path)
    store.reset_for_state("Discharging")

    assert store.claim("10p") is True
    assert store.claim("10p") is False

    store.reset_for_state("Charging")
    assert store.claim("10p") is True
