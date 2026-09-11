#!/usr/bin/env bash
# =============================================================================
# Infrastructure: deployment-specific configuration. The only place env vars
# and user-specific paths are read. Domain never touches these.
# =============================================================================

POWER_ROFI_THEME="${POWER_ROFI_THEME:-$HOME/.config/rofi/themes/waybar-menu.rasi}"
POWER_NOTIFY_APP="power"
POWER_NOTIFY_URGENCY="normal"
POWER_NOTIFY_FAIL_URGENCY="critical"