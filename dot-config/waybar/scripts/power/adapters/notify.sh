#!/usr/bin/env bash
# =============================================================================
# Driven adapter: notify-send backend for the notification gateway.
# =============================================================================

gateway_notify() { # $1 summary $2 body [$3 urgency]
  local urgency="${3:-$POWER_NOTIFY_URGENCY}"
  notify-send -a "$POWER_NOTIFY_APP" -u "$urgency" "$1" "$2"
}