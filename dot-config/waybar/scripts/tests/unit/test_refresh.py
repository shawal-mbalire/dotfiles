from datetime import datetime

from domain.constants import MODULE_TTL_MS
from domain.models import AudioStatus, BatteryStatus, NetworkStatus
from domain.workflows import power, refresh


def test_render_all_covers_every_cache_key():
    outputs = refresh.render_all(
        now=datetime(2026, 1, 2, 15, 4, 5),
        network=NetworkStatus(interface="wlan0", ip_address="10.0.0.2", wireless=True),
        battery=BatteryStatus(capacity=73, state="Discharging"),
        backlight_percent=40,
        nightlight_active=True,
        bluetooth_powered=False,
        audio=AudioStatus(volume_percent=26, muted=False),
        profile=power.validate_current("balanced"),
    )

    assert set(outputs) == set(MODULE_TTL_MS), "every cache key must be rendered"
    assert outputs["pill-network"].text
    assert outputs["power-status"].text == "Balanced"
