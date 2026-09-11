"""Static domain constants: business knowledge that never changes per machine.

Static constants (icons, cycle order, markup vocabulary, control thresholds)
live here. Deployment-specific values are injected from ``infra.config``.
"""

from __future__ import annotations

from domain.models import PowerProfile

# ── Power profiles ──────────────────────────────────────────────────────────
# Cycle order is the tuple order.

POWER_PROFILES: tuple[PowerProfile, ...] = (
    PowerProfile("power-saver", "Low power", "\U000f0f86", "power-saver"),
    PowerProfile("balanced", "Balanced", "\U000f0747", "balanced"),
    PowerProfile("performance", "Performance", "\U000f04c5", "performance"),
)

DEFAULT_POWER_PROFILE = "balanced"

POWER_ACCENTS: dict[str, str] = {
    "power-saver": "#89b4fa",
    "balanced": "#a6e3a1",
    "performance": "#f38ba8",
}

# ── Icons ───────────────────────────────────────────────────────────────────
ICON_CLOCK = "\U000f0954"
ICON_GAMMASTEP = "\U000f050f"
ICON_WIFI = "\U000f05a9"
ICON_ETHERNET = "\U000f0200"
ICON_VOLUME = "\U000f057e"
ICON_VOLUME_ALT = "\U000f0388"
ICON_VOLUME_MUTED = "\U000f075f"
ICON_BACKLIGHT = "\U000f00de"
ICON_BATTERY = "\U000f0079"
ICON_BLUETOOTH = "\U000f00af"
ICON_BT_CONNECTED = "\U000f00b1"
ICON_BT_AVAILABLE = "\U000f00b2"

# ── Markup vocabulary (Pango) ───────────────────────────────────────────────
MARKUP_CLOSE = "</span>"
MARKUP_LABEL = "<span foreground='#6c7086'>"
MARKUP_VALUE = "<span foreground='#cdd6f4'>"

ACCENT_CLOCK = "#fab387"
ACCENT_GAMMASTEP = "#f5c2e7"
ACCENT_NETWORK = "#b4befe"
ACCENT_AUDIO = "#74c7ec"
ACCENT_BRIGHTNESS = "#f9e2af"
ACCENT_BATTERY = "#a6e3a1"
ACCENT_BLUETOOTH = "#89b4fa"

# ── Brightness control ──────────────────────────────────────────────────────
BRIGHTNESS_LOW_PERCENT = 10
BRIGHTNESS_MID_PERCENT = 30
BRIGHTNESS_STEP_LOW = 1
BRIGHTNESS_STEP_MID = 2
BRIGHTNESS_STEP_HIGH = 5

BRIGHTNESS_PRESETS: tuple[str, ...] = ("10%", "25%", "50%", "75%", "100%")

# ── Volume control ──────────────────────────────────────────────────────────
VOLUME_TONE_VOLUME = 0.3

# ── Bluetooth ───────────────────────────────────────────────────────────────
BLUETOOTH_SCAN_SECONDS = 10

# ── Audio device description shortening ─────────────────────────────────────
AUDIO_DESCRIPTION_STRIP = "Core Ultra 200H/200V Series Processors HD Audio "
AUDIO_DESCRIPTION_CODEC = "Realtek ALC"
