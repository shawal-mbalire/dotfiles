"""Pure status rendering shared by the pill chips and the text modules.

Every function here is deterministic: given a domain value it returns a
:class:`ModuleOutput`. No I/O, no external commands — trivially testable.
"""

from __future__ import annotations

from datetime import datetime

from domain.constants import (
    ACCENT_AUDIO,
    ACCENT_BATTERY,
    ACCENT_BLUETOOTH,
    ACCENT_BRIGHTNESS,
    ACCENT_CLOCK,
    ACCENT_GAMMASTEP,
    ACCENT_NETWORK,
    ICON_BACKLIGHT,
    ICON_BATTERY,
    ICON_BLUETOOTH,
    ICON_CLOCK,
    ICON_ETHERNET,
    ICON_GAMMASTEP,
    ICON_VOLUME,
    ICON_VOLUME_MUTED,
    ICON_WIFI,
    MARKUP_CLOSE,
    MARKUP_LABEL,
    MARKUP_VALUE,
)
from domain.models import AudioStatus, BatteryStatus, ModuleOutput, NetworkStatus


def _title(text: str, accent: str) -> str:
    return f"<span foreground='{accent}' font_weight='bold'>{text}{MARKUP_CLOSE}"


def _row(label: str, value: str) -> str:
    return f"{MARKUP_LABEL}{label}{MARKUP_CLOSE}  {MARKUP_VALUE}{value}{MARKUP_CLOSE}"


def _tooltip(title: str, accent: str, rows: list[tuple[str, str]]) -> str:
    body = "\n".join(_row(label, value) for label, value in rows)
    return f"{_title(title, accent)}\n{body}"


def clock_output(now: datetime) -> ModuleOutput:
    date = now.strftime("%A, %B %d, %Y")
    return ModuleOutput(text=ICON_CLOCK, tooltip=_tooltip("CLOCK", ACCENT_CLOCK, [("Date", date)]))


def nightlight_tooltip(active: bool) -> str:
    return _tooltip("GAMMASTEP", ACCENT_GAMMASTEP, [("Status", "Active" if active else "Inactive")])


def nightlight_pill(active: bool) -> ModuleOutput:
    return ModuleOutput(text=ICON_GAMMASTEP, tooltip=nightlight_tooltip(active))


def nightlight_status(active: bool) -> ModuleOutput:
    return ModuleOutput(text="On" if active else "Off", tooltip=nightlight_tooltip(active))


def network_pill(status: NetworkStatus) -> ModuleOutput:
    icon = ICON_WIFI if status.wireless else ICON_ETHERNET
    tooltip = _tooltip(
        "NETWORK",
        ACCENT_NETWORK,
        [
            ("Interface", status.interface or "n/a"),
            ("IP", status.ip_address or "n/a"),
        ],
    )
    return ModuleOutput(text=icon, tooltip=tooltip)


def volume_tooltip(status: AudioStatus) -> str:
    return _tooltip(
        "AUDIO",
        ACCENT_AUDIO,
        [
            ("Volume", f"{status.volume_percent}%"),
            ("Mute", "Muted" if status.muted else "On"),
            ("Left-click", "Mute"),
            ("Right-click", "Devices"),
            ("Scroll", "Volume"),
        ],
    )


def volume_pill(status: AudioStatus) -> ModuleOutput:
    icon = ICON_VOLUME_MUTED if status.muted else ICON_VOLUME
    return ModuleOutput(text=icon, tooltip=volume_tooltip(status))


def audio_status_output(status: AudioStatus) -> ModuleOutput:
    text = "Muted" if status.muted else f"{status.volume_percent}%"
    css_class = "muted" if status.muted else ""
    return ModuleOutput(text=text, tooltip=volume_tooltip(status), css_class=css_class)


def backlight_pill(percent: int) -> ModuleOutput:
    tooltip = _tooltip(
        "BRIGHTNESS",
        ACCENT_BRIGHTNESS,
        [
            ("Level", f"{percent}%"),
            ("Scroll", "Adjust"),
            ("Right-click", "Presets"),
        ],
    )
    return ModuleOutput(text=ICON_BACKLIGHT, tooltip=tooltip)


def battery_pill(status: BatteryStatus) -> ModuleOutput:
    capacity = f"{status.capacity}%" if status.capacity is not None else "n/a%"
    tooltip = _tooltip(
        "BATTERY",
        ACCENT_BATTERY,
        [
            ("Capacity", capacity),
            ("Status", status.state or "Unknown"),
        ],
    )
    return ModuleOutput(text=ICON_BATTERY, tooltip=tooltip)


def bluetooth_pill(powered: bool) -> ModuleOutput:
    tooltip = _tooltip(
        "BLUETOOTH",
        ACCENT_BLUETOOTH,
        [
            ("Powered", "On" if powered else "Off"),
            ("Left-click", "Devices"),
            ("Right-click", "Power toggle"),
        ],
    )
    return ModuleOutput(text=ICON_BLUETOOTH, tooltip=tooltip)
