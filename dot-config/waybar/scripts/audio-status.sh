#!/usr/bin/env bash
# =============================================================================
# Audio status for the waybar custom/audio module. Emits JSON with markup
# tooltip so it matches the other modules.
# =============================================================================
set -u

VOL="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')"
if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED; then
  TEXT="Muted"
  MT="Muted"
  CLASS="muted"
else
  TEXT="${VOL}%"
  MT="On"
  CLASS=""
fi

K="<span foreground='#6c7086'>"
V="<span foreground='#cdd6f4'>"
E="</span>"
NL='\n'

TOOLTIP="<span foreground='#74c7ec' font_weight='bold'>AUDIO${E}${NL}${K}Volume${E}  ${V}${VOL}%${E}${NL}${K}Mute${E}  ${V}${MT}${E}${NL}${K}Left-click${E}  ${V}Mute${E}${NL}${K}Right-click${E}  ${V}Devices${E}${NL}${K}Scroll${E}  ${V}Volume${E}"

if [ -n "$CLASS" ]; then
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
else
  printf '{"text":"%s","tooltip":"%s"}\n' "$TEXT" "$TOOLTIP"
fi