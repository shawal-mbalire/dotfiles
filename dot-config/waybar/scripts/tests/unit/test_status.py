from datetime import datetime

from domain.constants import ICON_BATTERY, ICON_CLOCK, ICON_ETHERNET, ICON_VOLUME_MUTED, ICON_WIFI
from domain.models import AudioStatus, BatteryStatus, NetworkStatus
from domain.workflows import status


def test_clock_output_uses_time_port_value():
    output = status.clock_output(datetime(2026, 1, 2, 15, 4, 5))
    assert output.text == ICON_CLOCK
    assert "Friday, January 02, 2026" in output.tooltip


def test_network_pill_wireless_icon_and_details():
    output = status.network_pill(
        NetworkStatus(interface="wlan0", ip_address="10.0.0.2", wireless=True)
    )
    assert output.text == ICON_WIFI
    assert "wlan0" in output.tooltip and "10.0.0.2" in output.tooltip


def test_network_pill_ethernet_icon():
    output = status.network_pill(
        NetworkStatus(interface="eth0", ip_address="192.168.1.5", wireless=False)
    )
    assert output.text == ICON_ETHERNET


def test_volume_pill_muted_shows_muted_icon():
    output = status.volume_pill(AudioStatus(volume_percent=0, muted=True))
    assert output.text == ICON_VOLUME_MUTED
    assert "Muted" in output.tooltip


def test_audio_status_output_shows_percent_and_class():
    output = status.audio_status_output(AudioStatus(volume_percent=26, muted=False))
    assert output.text == "26%"
    assert output.css_class == ""

    muted = status.audio_status_output(AudioStatus(volume_percent=26, muted=True))
    assert muted.text == "Muted"
    assert muted.css_class == "muted"


def test_battery_pill_falls_back_when_unavailable():
    output = status.battery_pill(BatteryStatus(capacity=None, state=None))
    assert output.text == ICON_BATTERY
    assert "n/a%" in output.tooltip and "Unknown" in output.tooltip


def test_nightlight_status_text_tracks_state():
    assert status.nightlight_status(True).text == "On"
    assert status.nightlight_status(False).text == "Off"
    assert "Active" in status.nightlight_status(True).tooltip


def test_bluetooth_pill_reports_powered_state():
    assert "On" in status.bluetooth_pill(True).tooltip
    assert "Off" in status.bluetooth_pill(False).tooltip
