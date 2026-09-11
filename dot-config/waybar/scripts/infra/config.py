"""Infrastructure: deployment-specific configuration.

Reads environment variables and user-specific paths exactly once. This is the
only place in the codebase where the environment is inspected.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

DEFAULT_TIME_BUDGET_MS = 50
DEFAULT_BATTERY = "BAT0"
DEFAULT_BACKLIGHT_DEVICE = "intel_backlight"
DEFAULT_AUDIO_SINK = "@DEFAULT_AUDIO_SINK@"
DEFAULT_SOUND = "/usr/share/sounds/alsa/Front_Center.wav"
DEFAULT_GAMMASTEP_TEMPERATURE = "16000"

POWER_BUS = "net.hadess.PowerProfiles"
POWER_PATH = "/net/hadess/PowerProfiles"
POWER_IFACE = "net.hadess.PowerProfiles"

SIGNAL_AUDIO = 5
SIGNAL_POWER = 7
SIGNAL_FAST = 8


def _env(name: str, default: str) -> str:
    value = os.environ.get(name)
    return value if value else default


def _env_int(name: str, default: int) -> int:
    try:
        return int(_env(name, str(default)))
    except ValueError:
        return default


def _env_float(name: str, default: float) -> float:
    try:
        return float(_env(name, str(default)))
    except ValueError:
        return default


@dataclass(frozen=True)
class Config:
    """Typed, immutable configuration injected into every adapter."""

    time_budget_ms: int
    log_level: str
    battery_supply: str
    backlight_device: str
    audio_sink: str
    volume_step: int
    volume_max: float
    sound_path: str
    gammastep_temperature: str
    notify_app: str
    notify_urgency: str
    notify_fail_urgency: str
    prompt_theme: str
    power_bus: str = POWER_BUS
    power_path: str = POWER_PATH
    power_iface: str = POWER_IFACE
    signal_audio: int = SIGNAL_AUDIO
    signal_power: int = SIGNAL_POWER
    signal_fast: int = SIGNAL_FAST


def load_config() -> Config:
    """Read the environment and return a fully-populated config object."""
    return Config(
        time_budget_ms=_env_int("WAYBAR_TIME_BUDGET_MS", DEFAULT_TIME_BUDGET_MS),
        log_level=_env("WAYBAR_LOG_LEVEL", "warning"),
        battery_supply=_env("WAYBAR_BATTERY", DEFAULT_BATTERY),
        backlight_device=_env("WAYBAR_BACKLIGHT_DEVICE", DEFAULT_BACKLIGHT_DEVICE),
        audio_sink=_env("WAYBAR_AUDIO_SINK", DEFAULT_AUDIO_SINK),
        volume_step=_env_int("WAYBAR_VOLUME_STEP", 5),
        volume_max=_env_float("WAYBAR_VOLUME_MAX", 1.0),
        sound_path=_env("WAYBAR_SOUND", DEFAULT_SOUND),
        gammastep_temperature=_env("WAYBAR_GAMMASTEP_TEMPERATURE", DEFAULT_GAMMASTEP_TEMPERATURE),
        notify_app=_env("WAYBAR_NOTIFY_APP", "waybar"),
        notify_urgency=_env("WAYBAR_NOTIFY_URGENCY", "normal"),
        notify_fail_urgency=_env("WAYBAR_NOTIFY_FAIL_URGENCY", "critical"),
        prompt_theme=_env("WAYBAR_PROMPT_THEME", ""),
    )
