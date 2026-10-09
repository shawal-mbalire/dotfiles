"""View-model builder tests."""

from __future__ import annotations

from datetime import datetime

from domain.constants import theme_for
from domain.models import Audio, Battery, Bluetooth, NightLight, TrayItem, WorkspaceState
from domain.workflows.presentation import build_bar_model, build_control_center_model
from tests.fixtures.fakes import sample_network


def _bar(**overrides):
    defaults = dict(
        theme=theme_for(True),
        workspaces=WorkspaceState(),
        tray=(TrayItem(id="nm-applet", title="Network"), TrayItem(id="discord", title="Discord")),
        now=datetime(2026, 10, 9, 7, 5),
        nightlight=NightLight(active=False),
        network=sample_network(),
        bluetooth=Bluetooth(available=True, enabled=False, connected_name=""),
        audio=Audio(ready=True, muted=False, volume=40),
        brightness=70,
        battery=Battery(present=True, level=62, charging=False, state="Discharging"),
        brightness_available=True,
    )
    defaults.update(overrides)
    return build_bar_model(**defaults)


def test_bar_indicators_order_and_content():
    model = _bar()
    keys = [seg.key for seg in model.indicators]
    assert keys == ["nightlight", "network", "bluetooth", "volume", "brightness", "battery"]
    by_key = {seg.key: seg for seg in model.indicators}
    assert by_key["network"].label == "home"
    assert by_key["bluetooth"].label == "off"
    assert by_key["volume"].label == "40%"
    assert by_key["battery"].label == "62%"
    # battery tone normal → green
    assert by_key["battery"].glyph_color == theme_for(True).palette.green


def test_bar_filters_suppressed_tray_items():
    model = _bar()
    assert [item.id for item in model.tray] == ["discord"]


def test_bar_clock_and_workspaces():
    model = _bar()
    assert model.clock.date_text == "Oct 9"
    assert model.clock.time_text == "07:05"
    assert len(model.workspaces) == 10


def test_bar_hides_unavailable_battery_and_brightness():
    model = _bar(battery=Battery(present=False), brightness_available=False)
    by_key = {seg.key: seg for seg in model.indicators}
    assert by_key["battery"].visible is False
    assert by_key["brightness"].visible is False


def test_control_center_model():
    model = build_control_center_model(
        theme=theme_for(True),
        battery=Battery(present=True, level=62),
        audio=Audio(ready=True, muted=True, volume=0),
        brightness=70,
        brightness_available=True,
        network=sample_network(),
        history=(),
    )
    assert model.network_status == "home"
    assert model.network_connected is True
    assert model.volume.label == "Muted"
