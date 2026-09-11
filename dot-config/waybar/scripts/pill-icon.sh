#!/usr/bin/env bash
# =============================================================================
# Usage: pill-icon.sh {clock|temp|network|volume|backlight|battery|bluetooth}
# Emits {"text":"<icon>","tooltip":"<detailed>"} so the icon chip and the info
# text share ONE detailed tooltip per pill.
# =============================================================================
set -u

K="<span foreground='#6c7086'>"
V="<span foreground='#cdd6f4'>"
E="</span>"
NL='\n'

case "${1:-}" in
  clock)
    ICON='󰥔'
    TOOLTIP="<span foreground='#fab387' font_weight='bold'>CLOCK${E}${NL}${K}Date${E}  ${V}$(date '+%A, %B %d, %Y')${E}"
    ;;
  temp)
    ICON='󰔏'
    if pgrep -x gammastep >/dev/null 2>&1; then ST='Active'; else ST='Inactive'; fi
    TOOLTIP="<span foreground='#f5c2e7' font_weight='bold'>GAMMASTEP${E}${NL}${K}Status${E}  ${V}${ST}${E}"
    ;;
  network)
    IFACE="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')"
    IP="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4; exit}' | cut -d/ -f1)"
    if [ -n "${IFACE:-}" ] && iw dev "$IFACE" info >/dev/null 2>&1; then
      ICON='󰖩'
    else
      ICON='󰈀'
    fi
    TOOLTIP="<span foreground='#b4befe' font_weight='bold'>NETWORK${E}${NL}${K}Interface${E}  ${V}${IFACE:-n/a}${E}${NL}${K}IP${E}  ${V}${IP:-n/a}${E}"
    ;;
  volume)
    ICON='󰕾'
    VOL="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')"
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED; then MT='Muted'; else MT='On'; fi
    TOOLTIP="<span foreground='#74c7ec' font_weight='bold'>AUDIO${E}${NL}${K}Volume${E}  ${V}${VOL}%${E}${NL}${K}Mute${E}  ${V}${MT}${E}${NL}${K}Left-click${E}  ${V}Mute${E}${NL}${K}Right-click${E}  ${V}Devices${E}${NL}${K}Scroll${E}  ${V}Volume${E}"
    ;;
  backlight)
    ICON='󰃞'
    PERC="$(brightnessctl -m 2>/dev/null | cut -d, -f4)"
    TOOLTIP="<span foreground='#f9e2af' font_weight='bold'>BRIGHTNESS${E}${NL}${K}Level${E}  ${V}${PERC}${E}${NL}${K}Scroll${E}  ${V}Adjust${E}${NL}${K}Right-click${E}  ${V}Presets${E}"
    ;;
  battery)
    ICON='󰁹'
    CAP="$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)"
    ST="$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)"
    TOOLTIP="<span foreground='#a6e3a1' font_weight='bold'>BATTERY${E}${NL}${K}Capacity${E}  ${V}${CAP:-n/a}%${E}${NL}${K}Status${E}  ${V}${ST:-Unknown}${E}"
    ;;
  bluetooth)
    ICON='󰂯'
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then PW='On'; else PW='Off'; fi
    TOOLTIP="<span foreground='#89b4fa' font_weight='bold'>BLUETOOTH${E}${NL}${K}Powered${E}  ${V}${PW}${E}${NL}${K}Left-click${E}  ${V}Devices${E}${NL}${K}Right-click${E}  ${V}Power toggle${E}"
    ;;
  *)
    echo "usage: $0 {clock|temp|network|volume|backlight|battery|bluetooth}" >&2
    exit 1
    ;;
esac

printf '{"text":"%s","tooltip":"%s"}\n' "$ICON" "$TOOLTIP"