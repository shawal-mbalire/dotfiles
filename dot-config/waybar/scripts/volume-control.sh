#!/bin/bash

# Volume control with feedback tone
# Usage: volume-control.sh {up|down|mute}

SOUND="/usr/share/sounds/alsa/Front_Center.wav"
STEP="5%"
MAX="1.0"

case "${1:-}" in
    up)
        wpctl set-volume -l "$MAX" @DEFAULT_AUDIO_SINK@ "${STEP}+"
        ;;
    down)
        wpctl set-volume -l "$MAX" @DEFAULT_AUDIO_SINK@ "${STEP}-"
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute}" >&2
        exit 1
        ;;
esac

# Refresh waybar's volume module immediately (RTMIN+5) — the bar is the
# visual indicator now, no notification popup.
wb="$(pgrep -x waybar | head -n1)"
[ -n "$wb" ] && kill -RTMIN+5 "$wb" 2>/dev/null

# Play feedback tone
if command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND" ]; then
    pw-play --volume=0.3 "$SOUND" 2>/dev/null &
fi