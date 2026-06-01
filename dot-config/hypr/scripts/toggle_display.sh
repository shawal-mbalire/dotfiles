#!/bin/bash

# Monitor names as defined in hyprland.conf
PRIMARY="eDP-1"
SECONDARY="HDMI-A-2"

# Check the current status of the secondary monitor
# We look for "mirrorOf: <primary>" in the output of hyprctl monitors
MONITOR_INFO=$(hyprctl monitors | grep -A 20 "Monitor $SECONDARY")

if [ -z "$MONITOR_INFO" ]; then
    notify-send "Display" "$SECONDARY not detected" -i video-display
    exit 1
fi

if echo "$MONITOR_INFO" | grep -q "mirrorOf: $PRIMARY"; then
    # Currently mirroring, switch to extend
    # Position it to the right of the primary monitor (1920x0)
    hyprctl keyword monitor "$SECONDARY,highres,1920x0,1"
    notify-send "Display" "Mode: Extended (HDMI HighRes to the right)" -i video-display
else
    # Currently not mirroring, switch to mirror
    hyprctl keyword monitor "$SECONDARY,highres,0x0,1,mirror,$PRIMARY"
    notify-send "Display" "Mode: Mirrored (HDMI HighRes mirrors eDP-1)" -i video-display
fi
