#!/bin/bash

# Toggle secondary monitor between mirror and extend mode.
# Monitor names should match modules/displays.lua

PRIMARY="eDP-1"
SECONDARY="HDMI-A-2"

MONITOR_INFO=$(hyprctl monitors | grep -A 20 "Monitor $SECONDARY")

if [ -z "$MONITOR_INFO" ]; then
    notify-send "Display" "$SECONDARY not detected" -i video-display
    exit 1
fi

if echo "$MONITOR_INFO" | grep -q "mirrorOf: $PRIMARY"; then
    hyprctl keyword monitor "$SECONDARY,highres,1920x0,1"
    notify-send "Display" "Mode: Extended (HDMI HighRes to the right)" -i video-display
else
    hyprctl keyword monitor "$SECONDARY,highres,0x0,1,mirror,$PRIMARY"
    notify-send "Display" "Mode: Mirrored (HDMI HighRes mirrors eDP-1)" -i video-display
fi
