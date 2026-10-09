"""Domain constants — design tokens, glyphs, and policy values.

No magic numbers live in the domain: every numeric value is named here.
Static business knowledge is defined directly; deployment-specific values are
loaded from ``infra.config`` and injected.
"""

from __future__ import annotations

from dataclasses import dataclass

# ── Palette (Catppuccin Mocha / Latte) ─────────────────────────────────────


@dataclass(frozen=True, slots=True)
class Palette:
    rosewater: str
    flamingo: str
    pink: str
    mauve: str
    red: str
    maroon: str
    peach: str
    yellow: str
    green: str
    teal: str
    sky: str
    sapphire: str
    blue: str
    lavender: str
    text: str
    subtext1: str
    subtext0: str
    overlay2: str
    overlay1: str
    overlay0: str
    surface2: str
    surface1: str
    surface0: str
    base: str
    mantle: str
    crust: str


DARK = Palette(
    rosewater="#f5e0dc",
    flamingo="#f2cdcd",
    pink="#f5c2e7",
    mauve="#cba6f7",
    red="#f38ba8",
    maroon="#eba0ac",
    peach="#fab387",
    yellow="#f9e2af",
    green="#a6e3a1",
    teal="#94e2d5",
    sky="#89dceb",
    sapphire="#74c7ec",
    blue="#89b4fa",
    lavender="#b4befe",
    text="#cdd6f4",
    subtext1="#bac2de",
    subtext0="#a6adc8",
    overlay2="#9399b2",
    overlay1="#7f849c",
    overlay0="#6c7086",
    surface2="#585b70",
    surface1="#45475a",
    surface0="#313244",
    base="#1e1e2e",
    mantle="#181825",
    crust="#11111b",
)

LIGHT = Palette(
    rosewater="#dc8a78",
    flamingo="#dd7878",
    pink="#ea76cb",
    mauve="#8839ef",
    red="#d20f39",
    maroon="#e64553",
    peach="#fe640b",
    yellow="#df8e1d",
    green="#40a02b",
    teal="#179299",
    sky="#04a5e5",
    sapphire="#209fb5",
    blue="#1e66f5",
    lavender="#7287fd",
    text="#4c4f69",
    subtext1="#5c5f77",
    subtext0="#6c6f85",
    overlay2="#7c7f93",
    overlay1="#8c8fa1",
    overlay0="#9ca0b0",
    surface2="#acb0be",
    surface1="#bcc0cc",
    surface0="#ccd0da",
    base="#eff1f5",
    mantle="#e6e9ef",
    crust="#dce0e8",
)


@dataclass(frozen=True, slots=True)
class Theme:
    """The full design token set. Immutable — swapping is done by construction."""

    dark: bool
    palette: Palette

    # Typography
    font: str = "Comfortaa"
    nerd_font: str = "Hack Nerd Font"
    font_size: int = 15
    font_weight: int = 1000

    # Shape
    radius: int = 5
    radius_sm: int = 3
    radius_lg: int = 8

    # Spacing / padding
    spacing: int = 8
    spacing_sm: int = 4
    spacing_lg: int = 12
    padding: int = 12
    padding_sm: int = 8
    padding_lg: int = 16

    # Motion (milliseconds)
    anim_fast: int = 120
    anim_normal: int = 200
    anim_slow: int = 320


DARK_THEME = Theme(dark=True, palette=DARK)
LIGHT_THEME = Theme(dark=False, palette=LIGHT)


def theme_for(dark: bool) -> Theme:
    """Pure selector — the single way a theme is chosen."""
    return DARK_THEME if dark else LIGHT_THEME


# ── Layout constants ───────────────────────────────────────────────────────

BAR_HEIGHT = 30
BAR_MARGIN_X = 14
BAR_LEFT_SPACING = 6
BAR_RIGHT_SPACING = 20
CLOCK_SPACING = 6

WORKSPACE_COUNT = 10
WORKSPACE_HEIGHT = 20
WORKSPACE_WIDTH_ACTIVE = 32
WORKSPACE_WIDTH_IDLE = 22

TRAY_ITEM_SIZE = 20
TRAY_ICON_SIZE = 16
TRAY_SPACING = 4

CONTROL_CENTER_WIDTH = 320
MENU_WIDTH = 460
MENU_HEIGHT = 440
CLIPBOARD_WIDTH = 420
CLIPBOARD_HEIGHT = 460
NOTIFICATION_WIDTH = 360


# ── Audio / brightness ─────────────────────────────────────────────────────

VOLUME_MIN = 0
VOLUME_MAX = 150
VOLUME_BAR_CAP = 100
SCROLL_STEP = 5
BRIGHTNESS_MIN = 0
BRIGHTNESS_MAX = 100
BRIGHTNESS_POLL_MS = 500


# ── Indicator glyphs (Nerd Font private-use area) ──────────────────────────

GLYPH_BATTERY_CHARGING = 0xF0084
GLYPH_BATTERY_FULL = 0xF0079
GLYPH_BATTERY_EMPTY = 0xF0083
GLYPH_BATTERY_STEPS = 0xF007A
GLYPH_BLUETOOTH_OFF = 0xF00B2
GLYPH_BLUETOOTH_ON = 0xF00AF
GLYPH_BLUETOOTH_CONNECTED = 0xF00B1
GLYPH_BRIGHTNESS_OFF = 0xF00DA
GLYPH_BRIGHTNESS_LOW = 0xF00DC
GLYPH_BRIGHTNESS_MED = 0xF00DE
GLYPH_BRIGHTNESS_HIGH = 0xF00E0
GLYPH_VOLUME_MUTED = 0xF075F
GLYPH_VOLUME_OFF = 0xF0581
GLYPH_VOLUME_LOW = 0xF057F
GLYPH_VOLUME_MED = 0xF0580
GLYPH_VOLUME_HIGH = 0xF057E
GLYPH_WIFI_OFF = 0xF05AA
GLYPH_WIFI_DISCONNECTED = 0xF092D
GLYPH_WIFI_SIGNAL_BASE = 0xF091F
GLYPH_NIGHT_LIGHT = 0xF0594
GLYPH_DARK_MODE = 0xF0594
GLYPH_LIGHT_MODE = 0xF0599
GLYPH_POWER_PROFILE = 0xF04C5
GLYPH_SEARCH = 0xF0349
GLYPH_CLIPBOARD = 0xF014C
GLYPH_APP_FALLBACK = 0xF08C6
GLYPH_NOTIFICATION_FALLBACK = 0xF009A
GLYPH_CONTROL_CENTER = 0xF0493
GLYPH_LOCK = 0xF033E
GLYPH_CHEVRON = 0xF0140

BATTERY_CRITICAL = 15
BATTERY_LOW = 30
BRIGHTNESS_TIER_LOW = 34
BRIGHTNESS_TIER_HIGH = 67
VOLUME_TIER_LOW = 34
VOLUME_TIER_HIGH = 67
SIGNAL_STRONG = 0.75
SIGNAL_GOOD = 0.50
SIGNAL_WEAK = 0.25


# ── Clipboard policy ───────────────────────────────────────────────────────

CLIPBOARD_MAX_ITEMS = 50
CLIPBOARD_POLICY_MAX_ITEMS = 20
CLIPBOARD_MAX_CHARS = 32000
CLIPBOARD_POLICY_MAX_CHARS = 200000
CLIPBOARD_SAVE_DEBOUNCE_MS = 1000

# ── Notification policy ────────────────────────────────────────────────────

NOTIFICATION_MAX_VISIBLE = 5
NOTIFICATION_MAX_HISTORY = 20
NOTIFICATION_TIMEOUT_NORMAL_MS = 5000
NOTIFICATION_TIMEOUT_LOW_MS = 4000
NOTIFICATION_TIMEOUT_MAX_MS = 10000
NOTIFICATION_TICK_MS = 100
MS_PER_SECOND = 1000
SECONDS_THRESHOLD = 60

# ── Time / duration ────────────────────────────────────────────────────────

SECONDS_PER_MINUTE = 60
SECONDS_PER_HOUR = 3600

# ── Wallpaper policy ───────────────────────────────────────────────────────

WALLPAPER_EXTENSIONS = ("jpg", "jpeg", "png", "webp")

# ── System tray policy ─────────────────────────────────────────────────────

TRAY_SUPPRESS_PATTERN = (
    r"bluetooth|bluez|blueman|networkmanager|nm-applet|\bnetwork\b|wi-?fi|wireless|ethernet"
)

# ── Glyph rendering fallback ───────────────────────────────────────────────

GLYPH_MISSING = "\N{REPLACEMENT CHARACTER}"
