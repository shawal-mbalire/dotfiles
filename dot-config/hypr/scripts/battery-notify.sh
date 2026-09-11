#!/bin/bash

# Battery notification script for waybar + swaync.
# Triggers on: low battery (critical/high/normal), charging, full.

BAT="/sys/class/power_supply/BAT0"
CAPACITY=$(cat "$BAT/capacity" 2>/dev/null) || exit 0
STATUS=$(cat "$BAT/status" 2>/dev/null) || exit 0

NOTIFY_DIR="$HOME/.cache/battery-notify"
mkdir -p "$NOTIFY_DIR"

sent() {
    [ -f "$NOTIFY_DIR/$1" ] && return 0
    touch "$NOTIFY_DIR/$1"
    return 1
}

clear_sent() {
    rm -f "$NOTIFY_DIR"/*.sent 2>/dev/null
}

case "$STATUS" in
    Discharging)
        clear_sent
        if [ "$CAPACITY" -le 3 ]; then
            sent 3p || notify-send -a battery -u critical \
                "Critically Low Battery" \
                "${CAPACITY}% — plug in now!" \
                -i battery-caution
        elif [ "$CAPACITY" -le 10 ]; then
            sent 10p || notify-send -a battery -u high \
                "Low Battery" \
                "${CAPACITY}% remaining" \
                -i battery-low
        elif [ "$CAPACITY" -le 20 ]; then
            sent 20p || notify-send -a battery -u normal \
                "Battery" \
                "${CAPACITY}% remaining" \
                -i battery-full
        fi
        ;;
    Charging)
        clear_sent
        # Notify when charge crosses milestones while charging
        if [ "$CAPACITY" -ge 100 ]; then
            sent 100c || notify-send -a battery -u low \
                "Battery Full" \
                "100% — ready to unplug" \
                -i battery-full-charged
        elif [ "$CAPACITY" -ge 80 ]; then
            sent 80c || notify-send -a battery -u normal \
                "Battery" \
                "${CAPACITY}% — nearing full" \
                -i battery-full
        elif [ "$CAPACITY" -le 20 ]; then
            sent 20c || notify-send -a battery -u normal \
                "Charging" \
                "${CAPACITY}% — still low" \
                -i battery-low
        fi
        ;;
    Full)
        clear_sent
        sent full || notify-send -a battery -u low \
            "Battery Full" \
            "100%" \
            -i battery-full-charged
        ;;
esac
