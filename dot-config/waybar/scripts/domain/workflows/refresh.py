"""Refresh workflow: compose every module's status into its rendered output.

Pure: it takes already-fetched domain values and returns a mapping of cache
key to :class:`ModuleOutput`. The composition root gathers the values through
the adapters; this function owns *what* each module shows.
"""

from __future__ import annotations

from datetime import datetime

from domain.models import (
    AudioStatus,
    BatteryStatus,
    ModuleOutput,
    NetworkStatus,
    PowerProfile,
)
from domain.workflows import power as power_wf
from domain.workflows import status as status_wf


def render_all(
    *,
    now: datetime,
    network: NetworkStatus,
    battery: BatteryStatus,
    backlight_percent: int,
    nightlight_active: bool,
    bluetooth_powered: bool,
    audio: AudioStatus,
    profile: PowerProfile,
) -> dict[str, ModuleOutput]:
    return {
        "pill-clock": status_wf.clock_output(now),
        "pill-temp": status_wf.nightlight_pill(nightlight_active),
        "pill-network": status_wf.network_pill(network),
        "pill-volume": status_wf.volume_pill(audio),
        "pill-backlight": status_wf.backlight_pill(backlight_percent),
        "pill-battery": status_wf.battery_pill(battery),
        "pill-bluetooth": status_wf.bluetooth_pill(bluetooth_powered),
        "nightlight-status": status_wf.nightlight_status(nightlight_active),
        "audio-status": status_wf.audio_status_output(audio),
        "power-status": power_wf.status_output(profile),
        "power-pill": power_wf.pill_output(profile),
    }
