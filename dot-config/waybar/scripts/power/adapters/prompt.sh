#!/usr/bin/env bash
# =============================================================================
# Driving adapter: fuzzel selection menu, used by the `select` workflow.
# =============================================================================

gateway_prompt() { # $1 menu text $2 prompt
  printf '%b' "$1" | fuzzel --dmenu -p "$2" 2>/dev/null
}
