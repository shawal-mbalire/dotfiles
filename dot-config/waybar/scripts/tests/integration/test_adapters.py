"""Integration tests: exercise real adapters/sysfs on the host.

Each test skips itself when the underlying source is unavailable, so the suite
still runs on machines without a battery, bluetooth adapter, or PipeWire.
"""

from __future__ import annotations

import shutil
from pathlib import Path

import pytest
from domain.models import BatteryStatus, NetworkStatus


def test_proc_network_returns_a_status():
    from adapters.proc_network import ProcNetwork

    status = ProcNetwork().status()
    assert isinstance(status, NetworkStatus)


def test_rfkill_bluetooth_returns_bool():
    from adapters.rfkill_bluetooth import RfkillBluetoothPower

    assert isinstance(RfkillBluetoothPower().is_powered(), bool)


def test_sysfs_battery_reads_capacity_when_present():
    if not Path("/sys/class/power_supply/BAT0").exists():
        pytest.skip("no BAT0 on this machine")

    from adapters.sysfs_battery import SysfsBattery

    status = SysfsBattery("BAT0").status()
    assert isinstance(status, BatteryStatus)
    assert status.capacity is None or 0 <= status.capacity <= 100


def test_sysfs_backlight_returns_percentage_when_present():
    if not any(Path("/sys/class/backlight").glob("*")):
        pytest.skip("no backlight on this machine")

    from adapters.sysfs_backlight import SysfsBacklight

    percent = SysfsBacklight("").get_percent()
    assert 0 <= percent <= 100


def test_wpctl_audio_parses_live_output():
    if shutil.which("wpctl") is None:
        pytest.skip("wpctl not installed")

    from adapters.wpctl_audio import WpctlAudioControl

    status = WpctlAudioControl("@DEFAULT_AUDIO_SINK@").get_status()
    assert 0 <= status.volume_percent <= 100


def test_busctl_power_reads_live_profile():
    if shutil.which("busctl") is None:
        pytest.skip("busctl not installed")

    from adapters.busctl_power import BusctlPowerGateway
    from infra.config import POWER_BUS, POWER_IFACE, POWER_PATH

    active = BusctlPowerGateway(POWER_BUS, POWER_PATH, POWER_IFACE).get_active()
    assert active is None or active in {"power-saver", "balanced", "performance"}
