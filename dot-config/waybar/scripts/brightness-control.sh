#!/bin/bash
# Smooth brightness control with smaller steps at low brightness
ACTION="${1:-up}"
LOCK="/tmp/brightness-lock"

(
  flock -n 9 || exit 0

  CURRENT=$(brightnessctl get)
  MAX=$(brightnessctl max)
  PCT=$((CURRENT * 100 / MAX))

  if [ "$ACTION" = "up" ]; then
    if [ "$PCT" -lt 10 ]; then
      STEP=1
    elif [ "$PCT" -lt 30 ]; then
      STEP=2
    else
      STEP=5
    fi
    brightnessctl s "${STEP}%+"
  else
    if [ "$PCT" -le 10 ]; then
      STEP=1
    elif [ "$PCT" -le 30 ]; then
      STEP=2
    else
      STEP=5
    fi
    NEW_PCT=$((PCT - STEP))
    [ "$NEW_PCT" -lt 1 ] && STEP=$((PCT - 1))
    [ "$STEP" -gt 0 ] && brightnessctl s "${STEP}%-"
  fi
) 9>"$LOCK"
