"""Pure view-model builders.

These functions turn a set of port readings into immutable view models. No I/O,
no theme mutation — the driving adapter only renders what is returned here.
"""

from __future__ import annotations

from datetime import datetime

from domain import constants as C
from domain import logic
from domain.constants import Theme
from domain.models import (
    Audio,
    BarModel,
    Battery,
    Bluetooth,
    ClockSegment,
    ControlCenterModel,
    Network,
    NightLight,
    NotificationEntry,
    Segment,
    TrayItem,
    WorkspacePill,
    WorkspaceState,
)


def _battery_segment(theme: Theme, battery: Battery) -> Segment:
    tone = logic.tone_key_for_battery(battery.level, battery.charging)
    color = getattr(theme.palette, tone)
    return Segment(
        key="battery",
        glyph=logic.icon_for_battery(battery.level, battery.charging),
        label=f"{battery.level}%",
        glyph_color=color,
        label_color=theme.palette.text,
        visible=battery.present,
    )


def _brightness_segment(theme: Theme, brightness_percent: int, available: bool) -> Segment:
    color = theme.palette.overlay0 if brightness_percent == 0 else theme.palette.yellow
    return Segment(
        key="brightness",
        glyph=logic.icon_for_brightness(brightness_percent),
        label=f"{brightness_percent}%",
        glyph_color=color,
        label_color=theme.palette.text,
        visible=available,
    )


def _volume_segment(theme: Theme, audio: Audio) -> Segment:
    glyph_color = theme.palette.overlay1 if audio.muted else theme.palette.yellow
    label_color = theme.palette.overlay1 if audio.muted else theme.palette.text
    label = "_" if not audio.ready else ("Muted" if audio.muted else f"{audio.volume}%")
    return Segment(
        key="volume",
        glyph=logic.icon_for_volume(audio.volume, audio.muted, audio.ready),
        label=label,
        glyph_color=glyph_color,
        label_color=label_color,
        visible=True,
    )


def _bluetooth_segment(theme: Theme, bluetooth: Bluetooth) -> Segment:
    connected = bluetooth.connected_name != ""
    color = theme.palette.blue if bluetooth.enabled else theme.palette.overlay0
    if not bluetooth.enabled:
        label = "off"
    elif connected:
        label = bluetooth.connected_name
    else:
        label = "on"
    return Segment(
        key="bluetooth",
        glyph=logic.icon_for_bluetooth(bluetooth.enabled, connected),
        label=label,
        glyph_color=color,
        label_color=color,
        visible=bluetooth.available,
        max_label_width=140,
    )


def _network_segment(theme: Theme, network: Network) -> Segment:
    if not network.wifi_enabled:
        label = "off"
    elif network.connected:
        label = network.ssid
    else:
        label = "Disconnected"
    color = theme.palette.pink if network.wifi_enabled else theme.palette.overlay0
    return Segment(
        key="network",
        glyph=logic.icon_for_wifi(network.strength, network.wifi_enabled, network.connected),
        label=label,
        glyph_color=color,
        label_color=color,
        max_label_width=160,
    )


def _nightlight_segment(theme: Theme, nightlight: NightLight) -> Segment:
    color = theme.palette.peach if nightlight.active else theme.palette.overlay0
    return Segment(
        key="nightlight",
        glyph=logic.glyph(C.GLYPH_NIGHT_LIGHT),
        label="",
        glyph_color=color,
        label_color=color,
    )


def build_bar_model(
    *,
    theme: Theme,
    workspaces: WorkspaceState,
    tray: tuple[TrayItem, ...],
    now: datetime,
    nightlight: NightLight,
    network: Network,
    bluetooth: Bluetooth,
    audio: Audio,
    brightness: int,
    battery: Battery,
    brightness_available: bool,
) -> BarModel:
    """Assemble the whole bar from readings. Pure."""
    date_text, time_text = logic.format_clock(now)
    pills = tuple(WorkspacePill(*pill) for pill in logic.workspace_pills(workspaces))
    visible_tray = tuple(
        item for item in tray if not logic.is_tray_item_suppressed(item.id, item.title)
    )
    indicators = (
        _nightlight_segment(theme, nightlight),
        _network_segment(theme, network),
        _bluetooth_segment(theme, bluetooth),
        _volume_segment(theme, audio),
        _brightness_segment(theme, brightness, brightness_available),
        _battery_segment(theme, battery),
    )
    return BarModel(
        workspaces=pills,
        tray=visible_tray,
        clock=ClockSegment(
            date_text=date_text,
            time_text=time_text,
            date_color=theme.palette.overlay0,
            time_color=theme.palette.text,
        ),
        indicators=indicators,
    )


def build_control_center_model(
    *,
    theme: Theme,
    battery: Battery,
    audio: Audio,
    brightness: int,
    brightness_available: bool,
    network: Network,
    history: tuple[NotificationEntry, ...],
) -> ControlCenterModel:
    """Assemble the control-center card model. Pure."""
    if not network.wifi_enabled:
        status = "Wi-Fi off"
    elif network.connected:
        status = network.ssid
    else:
        status = "Disconnected"
    return ControlCenterModel(
        battery=_battery_segment(theme, battery),
        volume=_volume_segment(theme, audio),
        brightness=_brightness_segment(theme, brightness, brightness_available),
        network_status=status,
        network_connected=network.connected,
        notifications=history,
        fields={
            "wifi_enabled": network.wifi_enabled,
            "bluetooth_enabled": False,
            "night_light_active": False,
            "muted": audio.muted,
            "volume": audio.volume,
            "brightness": brightness,
            "network_strength": network.strength,
            "brightness_available": brightness_available,
        },
    )
