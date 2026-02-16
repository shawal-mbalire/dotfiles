#!/bin/bash

# This script sends battery notifications using mako.
#
# Add this to your waybar config's battery module:
# "on-update": "bash ~/.config/hypr/scripts/battery-notify.sh"

CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

if [ "$STATUS" = "Discharging" ]; then
    if [ "$CAPACITY" -le 3 ]; then
        notify-send "Low Battery" "Battery level is ${CAPACITY}%!" -u critical -a 'battery'
    elif [ "$CAPACITY" -le 10 ]; then
        notify-send "Low Battery" "Battery level is ${CAPACITY}%!" -u high -a 'battery'
    elif [ "$CAPACITY" -le 20 ]; then
        notify-send "Low Battery" "Battery level is ${CAPACITY}%!" -u normal -a 'battery'
    fi
fi
