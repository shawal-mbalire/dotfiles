#!/bin/bash

# Toggle waybar on/off
if pgrep -x "waybar" > /dev/null; then
    pkill -x waybar
else
    waybar &
fi
