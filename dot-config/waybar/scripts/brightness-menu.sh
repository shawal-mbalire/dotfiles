#!/bin/bash
# Brightness preset menu (right-click on the backlight module).
CHOSEN=$(printf '10%%\n25%%\n50%%\n75%%\n100%%' | fuzzel --dmenu -p "Brightness" 2>/dev/null)
[ -n "$CHOSEN" ] && brightnessctl s "$CHOSEN"