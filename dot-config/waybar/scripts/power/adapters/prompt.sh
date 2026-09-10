#!/usr/bin/env bash
# =============================================================================
# Driving adapter: rofi selection menu, used by the `select` workflow.
# =============================================================================

gateway_prompt() { # $1 menu text $2 prompt
  printf '%b' "$1" | rofi -dmenu -p "$2" -i -theme "$POWER_ROFI_THEME" 2>/dev/null
}