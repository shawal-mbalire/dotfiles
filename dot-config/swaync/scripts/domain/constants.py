"""Static domain constants: vocabulary and structural rules.

These never change per machine. Deployment-specific values (colours, sizes,
commands, paths) live in ``infra.config`` and are injected at the composition
root.
"""

from __future__ import annotations

# ── Widget vocabulary ───────────────────────────────────────────────────────
WIDGET_MPRIS = "mpris"
WIDGET_BUTTONS_GRID = "buttons-grid"
WIDGET_VOLUME = "volume"
# swaync's backlight widget is registered as "backlight" (not "brightness").
WIDGET_BACKLIGHT = "backlight"
WIDGET_NOTIFICATIONS = "notifications"

WIDGET_INSTANCE_CLEARBAR = "clearbar"

# ── Panel vocabulary ────────────────────────────────────────────────────────
POSITION_LEFT = "left"
POSITION_RIGHT = "right"
POSITION_CENTER = "center"

VERTICAL_TOP = "top"
VERTICAL_BOTTOM = "bottom"
VERTICAL_CENTER = "center"

LAYER_OVERLAY = "overlay"
LAYER_TOP = "top"

# ── CSS selector structure (stable swaync/GTK class names) ──────────────────
SELECTOR_FLOATING = ".floating-notifications.background"
SELECTOR_CONTROL_CENTER = ".control-center"

# Default empty-state / copy
TEXT_EMPTY_FALLBACK = "No Notifications"


def panel_selectors(suffix: str) -> tuple[str, ...]:
    """The same card style applied to popups and the control center."""
    return (f"{SELECTOR_FLOATING} {suffix}", f"{SELECTOR_CONTROL_CENTER} {suffix}")
