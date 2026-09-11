"""Infrastructure: deployment-specific configuration.

Reads environment variables exactly once. This is the only place in the
codebase where the environment is inspected; the resulting ``Config`` is handed
to workflows by the composition root.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from domain.models import (
    AlbumArt,
    Button,
    Color,
    CssDeclaration,
    DesignTokens,
    ImageVisibility,
    Margins,
)

from infra.paths import output_dir

DEFAULT_SCHEMA = "/etc/xdg/swaync/configSchema.json"

# ── Palette (Catppuccin Mocha, shared with waybar) ──────────────────────────
PALETTE: tuple[tuple[str, str], ...] = (
    ("base", "#1e1e2e"),
    ("mantle", "#181825"),
    ("crust", "#11111b"),
    ("text", "#cdd6f4"),
    ("subtext0", "#a6adc8"),
    ("subtext1", "#bac2de"),
    ("overlay0", "#6c7086"),
    ("overlay1", "#7f849c"),
    ("surface0", "#313244"),
    ("surface1", "#45475a"),
    ("surface2", "#585b70"),
    ("blue", "#89b4fa"),
    ("lavender", "#b4befe"),
    ("sapphire", "#74c7ec"),
    ("sky", "#89dceb"),
    ("teal", "#94e2d5"),
    ("green", "#a6e3a1"),
    ("yellow", "#f9e2af"),
    ("peach", "#fab387"),
    ("maroon", "#eba0ac"),
    ("red", "#f38ba8"),
    ("mauve", "#cba6f7"),
    ("pink", "#f5c2e7"),
    ("flamingo", "#f2cdcd"),
)

# Colour cycle applied to the buttons-grid chips (matches the waybar icon chips).
ACCENT_CYCLE: tuple[str, ...] = (
    "lavender",
    "blue",
    "pink",
    "mauve",
    "green",
    "peach",
    "red",
    "sky",
    "teal",
)

# The waybar pill design language, resolved to CSS values.
DESIGN_TOKENS = DesignTokens(
    radius_pill="9px",
    radius_card="12px",
    radius_inner="7px",
    radius_small="6px",
    transition="all 0.25s ease",
    field_background="alpha(@surface0, 0.5)",
    field_border="1px solid alpha(@surface1, 0.6)",
    hover_border="alpha(@overlay1, 0.8)",
    card_background="alpha(@mantle, 0.95)",
    card_border="1px solid alpha(@mauve, 0.55)",
    card_shadow="0 8px 30px alpha(@crust, 0.5)",
    glow_blur="0 0 10px",
    # Every grid chip gets the same allotment, like the waybar icon chips.
    grid_button_width="88px",
    grid_button_height="40px",
    # Thin rule between control-center sections (visible but muted).
    divider="1px solid alpha(@surface2, 0.5)",
    # GTK ignores min-width percentages, so Clear All uses a fixed width that
    # spans a full 3-chip row.
    clear_button_width="340px",
)

ROOT_TOKENS: tuple[CssDeclaration, ...] = (
    CssDeclaration("--notification-icon-size", "40px"),
    CssDeclaration(
        "--notification-app-icon-size",
        "calc(var(--notification-icon-size) / 3)",
    ),
    CssDeclaration("--notification-group-icon-size", "32px"),
    CssDeclaration("--mpris-album-art-icon-size", "96px"),
    CssDeclaration("--widget-volume-row-icon-size", "24px"),
    # Align swaync's own variables with Catppuccin so nothing falls back to the
    # default Adwaita palette (RGB triplets are consumed via rgba(var(--x), a)).
    CssDeclaration("--cc-bg", "alpha(@base, 0.96)"),
    CssDeclaration("--noti-bg", "30, 30, 46"),
    CssDeclaration("--noti-bg-alpha", "0.95"),
    CssDeclaration("--noti-bg-darker", "17, 17, 27"),
    CssDeclaration("--noti-bg-hover", "49, 50, 68"),
    CssDeclaration("--noti-bg-focus", "alpha(@surface0, 0.6)"),
    CssDeclaration("--noti-close-bg", "49, 50, 68"),
    CssDeclaration("--noti-close-bg-hover", "69, 71, 90"),
    CssDeclaration("--noti-border-color", "alpha(@surface1, 0.6)"),
    CssDeclaration("--text-color", "@text"),
    CssDeclaration("--text-color-disabled", "@overlay0"),
    CssDeclaration("--bg-selected", "@blue"),
    CssDeclaration("--border", "1px solid alpha(@surface1, 0.6)"),
    CssDeclaration("--border-radius", "12px"),
    CssDeclaration("--notification-shadow", "0 8px 30px alpha(@crust, 0.5)"),
    CssDeclaration("--font-size-body", "13px"),
    CssDeclaration("--font-size-summary", "15px"),
    CssDeclaration("--hover-transition", "all 0.25s ease"),
    CssDeclaration("--group-collapse-transition", "opacity 200ms ease-in-out"),
)

# Commands invoked by the grid (single source of truth, env-overridable).
# swaync itself runs each command through `/bin/sh -c "..."`, so do NOT wrap
# them in another `sh -c` and avoid double quotes (they break its parser).
COMMANDS: dict[str, str] = {
    "wifi": "[ $SWAYNC_TOGGLE_STATE = true ] && nmcli radio wifi off || nmcli radio wifi on",
    "wifi_status": "nmcli radio wifi | grep -q enabled && echo true || echo false",
    "bluetooth": "[ $SWAYNC_TOGGLE_STATE = true ] && bluetoothctl power off "
    "|| bluetoothctl power on",
    "bluetooth_status": "bluetoothctl show | grep -qi 'powered: yes' && echo true || echo false",
    "nightlight": "[ $SWAYNC_TOGGLE_STATE = true ] && gammastep -x || gammastep -O 3500K",
    "nightlight_status": "gammastep -p 2>/dev/null | grep -qi override && echo true || echo false",
    "dnd": "swaync-client -d",
    "dnd_status": "swaync-client -D",
    "power": "~/.config/waybar/scripts/main.py power select",
    "screenshot": "grimblast --freeze copysave area",
    "clipboard": "cliphist wipe",
    "lock": "hyprlock",
    "sleep": "systemctl suspend",
    "clear": "swaync-client -C",
    "reload": "swaync-client -R && swaync-client -rs",
}


def _env(name: str, default: str) -> str:
    value = os.environ.get(name)
    return value if value else default


def _env_int(name: str, default: int) -> int:
    try:
        return int(_env(name, str(default)))
    except ValueError:
        return default


def _env_bool(name: str, default: bool) -> bool:
    return _env(name, "true" if default else "false").lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Config:
    """Typed, immutable configuration injected into every workflow."""

    # Output
    output_dir: Path
    schema: str

    # Logging
    log_level: str

    # Panel geometry
    position_x: str
    position_y: str
    layer: str
    control_center_layer: str
    margins: Margins
    notification_width: int
    control_center_width: int
    control_center_height: int
    fit_to_screen: bool

    # Behaviour
    layer_shell: bool
    layer_shell_cover_screen: bool
    css_priority: str
    transition_time_ms: int
    timeout: int
    timeout_low: int
    timeout_critical: int
    hide_on_clear: bool
    hide_on_action: bool
    text_empty: str
    script_fail_notify: bool
    notification_2fa_action: bool
    inline_replies: bool
    grouping: bool
    relative_timestamps: bool
    image_visibility: ImageVisibility
    keyboard_shortcuts: bool

    # Widgets
    mpris_image_radius: int
    mpris_autohide: bool
    mpris_show_album_art: AlbumArt
    volume_icon: str
    backlight_icon: str
    notifications_vexpand: bool
    buttons_per_row: int
    clear_buttons_per_row: int
    buttons: tuple[Button, ...]
    clear_buttons: tuple[Button, ...]

    # Style
    palette: tuple[Color, ...]
    tokens: DesignTokens
    root_tokens: tuple[CssDeclaration, ...]
    accent_cycle: tuple[str, ...]

    # Commands
    reload_command: str


def _buttons() -> tuple[Button, ...]:
    return (
        Button.toggle(
            "\U000f0928  Wifi",
            COMMANDS["wifi"],
            COMMANDS["wifi_status"],
            active=True,
        ),
        Button.toggle(
            "\U000f00af  BT",
            COMMANDS["bluetooth"],
            COMMANDS["bluetooth_status"],
            active=True,
        ),
        Button.toggle(
            "\U000f06e8  Night",
            COMMANDS["nightlight"],
            COMMANDS["nightlight_status"],
            active=True,
        ),
        Button.toggle(
            "\U000f009b  DND",
            COMMANDS["dnd"],
            COMMANDS["dnd_status"],
        ),
        Button.action("\U000f040a  Power", COMMANDS["power"]),
        Button.action("\U000f0e51  Shot", COMMANDS["screenshot"]),
        Button.action("\U000f014c  Clip", COMMANDS["clipboard"]),
        Button.action("\U000f033e  Lock", COMMANDS["lock"]),
        Button.action("\U000f0904  Sleep", COMMANDS["sleep"]),
    )


def _clear_buttons() -> tuple[Button, ...]:
    return (Button.action("\U000f0156  Clear All", COMMANDS["clear"]),)


def load_config() -> Config:
    """Read the environment and return a fully-populated config object."""
    return Config(
        output_dir=output_dir(),
        schema=_env("SWAYNC_SCHEMA", DEFAULT_SCHEMA),
        log_level=_env("SWAYNC_LOG_LEVEL", "warning"),
        position_x=_env("SWAYNC_POSITION_X", "right"),
        position_y=_env("SWAYNC_POSITION_Y", "top"),
        layer=_env("SWAYNC_LAYER", "overlay"),
        control_center_layer=_env("SWAYNC_CC_LAYER", "top"),
        margins=Margins(top=0, bottom=0, right=0, left=0),
        notification_width=_env_int("SWAYNC_NOTIFICATION_WIDTH", 380),
        control_center_width=_env_int("SWAYNC_CC_WIDTH", 380),
        control_center_height=_env_int("SWAYNC_CC_HEIGHT", 600),
        fit_to_screen=_env_bool("SWAYNC_FIT_TO_SCREEN", True),
        layer_shell=_env_bool("SWAYNC_LAYER_SHELL", True),
        layer_shell_cover_screen=_env_bool("SWAYNC_LAYER_SHELL_COVER", True),
        css_priority=_env("SWAYNC_CSS_PRIORITY", "user"),
        transition_time_ms=_env_int("SWAYNC_TRANSITION_MS", 200),
        timeout=_env_int("SWAYNC_TIMEOUT", 6),
        timeout_low=_env_int("SWAYNC_TIMEOUT_LOW", 3),
        timeout_critical=_env_int("SWAYNC_TIMEOUT_CRITICAL", 0),
        hide_on_clear=_env_bool("SWAYNC_HIDE_ON_CLEAR", False),
        hide_on_action=_env_bool("SWAYNC_HIDE_ON_ACTION", True),
        text_empty=_env("SWAYNC_TEXT_EMPTY", "No Notifications"),
        script_fail_notify=_env_bool("SWAYNC_SCRIPT_FAIL_NOTIFY", True),
        notification_2fa_action=_env_bool("SWAYNC_2FA_ACTION", True),
        inline_replies=_env_bool("SWAYNC_INLINE_REPLIES", True),
        grouping=_env_bool("SWAYNC_GROUPING", True),
        relative_timestamps=_env_bool("SWAYNC_RELATIVE_TIMESTAMPS", True),
        image_visibility=ImageVisibility.WHEN_AVAILABLE,
        keyboard_shortcuts=_env_bool("SWAYNC_KEYBOARD_SHORTCUTS", True),
        mpris_image_radius=_env_int("SWAYNC_MPRIS_IMAGE_RADIUS", 12),
        mpris_autohide=_env_bool("SWAYNC_MPRIS_AUTOHIDE", True),
        mpris_show_album_art=AlbumArt.ALWAYS,
        volume_icon=_env("SWAYNC_VOLUME_ICON", "\U000f057e"),
        backlight_icon=_env("SWAYNC_BACKLIGHT_ICON", "\U000f00e0"),
        notifications_vexpand=True,
        buttons_per_row=_env_int("SWAYNC_BUTTONS_PER_ROW", 3),
        clear_buttons_per_row=_env_int("SWAYNC_CLEAR_BUTTONS_PER_ROW", 1),
        buttons=_buttons(),
        clear_buttons=_clear_buttons(),
        palette=tuple(Color.from_hex(name, value) for name, value in PALETTE),
        tokens=DESIGN_TOKENS,
        root_tokens=ROOT_TOKENS,
        accent_cycle=ACCENT_CYCLE,
        reload_command=_env("SWAYNC_RELOAD", COMMANDS["reload"]),
    )
