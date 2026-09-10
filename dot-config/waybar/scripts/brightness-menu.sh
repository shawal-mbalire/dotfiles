#!/bin/bash
# Brightness preset menu (right-click on the backlight module).
CHOSEN=$(printf '10%%\n25%%\n50%%\n75%%\n100%%' | rofi -dmenu -p "Brightness" -i -theme "$HOME/.config/rofi/themes/waybar-menu.rasi" 2>/dev/null)
[ -n "$CHOSEN" ] && brightnessctl s "$CHOSEN"