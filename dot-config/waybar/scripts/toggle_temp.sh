#!/bin/bash

if ! command -v gammastep &> /dev/null; then
    notify-send "Gammastep" "Error: gammastep not found"
    exit 1
fi

if pgrep -x "gammastep" > /dev/null; then
    pkill gammastep
    notify-send "Gammastep" "Disabled"
    echo "off"
else
    gammastep -O 16000 &
    notify-send "Gammastep" "Enabled (16000K)"
    echo "on"
fi
