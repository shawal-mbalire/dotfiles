#!/usr/bin/env bash
# =============================================================================
# Composition root: the only place where everything is wired together.
# Reads infra config, instantiates adapters, injects them into the domain,
# and exposes a CLI used by waybar and keybindings.
#
# Usage: power.sh {status|cycle|select|set <profile>}
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# infra (config) -> ports (contract) -> adapters (implement ports) -> domain (pure)
# shellcheck source=/dev/null
source "$SCRIPT_DIR/infra.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/ports.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/adapters/ppd.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/adapters/notify.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/adapters/prompt.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/domain.sh"

# resolve_current -> prints a known profile name from the tuned adapter,
# normalised through the domain so unknown names never leak outward.
resolve_current() {
  local raw
  raw="$(gateway_get_active || true)"
  power_validate_current "$raw"
}

# --- Workflows --------------------------------------------------------------

# profile_color -> accent used in the markup tooltip title
profile_color() {
  case "$1" in
    power-saver) printf '#89b4fa' ;;
    balanced) printf '#a6e3a1' ;;
    performance) printf '#f38ba8' ;;
    *) printf '#a6e3a1' ;;
  esac
}

# power_tooltip <color> <label> -> markup tooltip (matches the other modules)
power_tooltip() {
  local nl='\n'
  printf "<span foreground=\x27%s\x27 font_weight=\x27bold\x27>POWER</span>%s<span foreground=\x27#6c7086\x27>Profile</span>  <span foreground=\x27#cdd6f4\x27>%s</span>" \
    "$1" "$nl" "$2"
}

cmd_status() { # JSON for the waybar custom/power text module
  local name label class color
  name="$(resolve_current)"
  label="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_LABEL")"
  class="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_CLASS")"
  color="$(profile_color "$class")"
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$label" "$class" "$(power_tooltip "$color" "$label")"
}

cmd_pill() { # JSON for the waybar custom/icon-power chip module
  local name icon label class color
  name="$(resolve_current)"
  icon="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_ICON")"
  label="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_LABEL")"
  class="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_CLASS")"
  color="$(profile_color "$class")"
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$icon" "$class" "$(power_tooltip "$color" "$label")"
}

# refresh_bar -> re-run the power modules immediately after a change
refresh_bar() {
  local wb
  wb="$(pgrep -x waybar | head -n1)"
  [[ -n "$wb" ]] && kill -RTMIN+7 "$wb" 2>/dev/null || true
}

cmd_cycle() {
  local current next label
  current="$(resolve_current)"
  next="$(power_next_profile "$current")"
  label="$(power_profile_field "$next" "$POWER_PROFILE_FIELD_LABEL")"
  if gateway_set_profile "$next"; then
    gateway_notify "Power Profile" "Switched to: $label"
    refresh_bar
  else
    gateway_notify "Power Profile" "Failed to switch to: $label" "$POWER_NOTIFY_FAIL_URGENCY"
    exit 1
  fi
}

cmd_select() {
  local menu="" current chosen chosen_clean name label
  current="$(resolve_current)"
  while IFS= read -r name; do
    label="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_LABEL")"
    if [[ "$name" == "$current" ]]; then
      menu+="${label}  ✓\n"
    else
      menu+="${label}\n"
    fi
  done < <(power_profile_names)

  chosen="$(gateway_prompt "$menu" "Power Profile")"
  [[ -n "$chosen" ]] || exit 0
  chosen_clean="${chosen%  ✓}"

  while IFS= read -r name; do
    label="$(power_profile_field "$name" "$POWER_PROFILE_FIELD_LABEL")"
    if [[ "$label" == "$chosen_clean" ]]; then
      if gateway_set_profile "$name"; then
        gateway_notify "Power Profile" "Switched to: $label"
        refresh_bar
      else
        gateway_notify "Power Profile" "Failed to switch to: $label" "$POWER_NOTIFY_FAIL_URGENCY"
        exit 1
      fi
      return 0
    fi
  done < <(power_profile_names)
}

cmd_set() { # $1 profile name
  if ! power_profile_exists "$1"; then
    gateway_notify "Power Profile" "Unknown profile: $1" "$POWER_NOTIFY_FAIL_URGENCY"
    exit 1
  fi
  local label
  label="$(power_profile_field "$1" "$POWER_PROFILE_FIELD_LABEL")"
  if gateway_set_profile "$1"; then
    gateway_notify "Power Profile" "Switched to: $label"
    refresh_bar
  else
    gateway_notify "Power Profile" "Failed to switch to: $label" "$POWER_NOTIFY_FAIL_URGENCY"
    exit 1
  fi
}

# --- CLI dispatch ------------------------------------------------------------

case "${1:-status}" in
  status) cmd_status ;;
  pill) cmd_pill ;;
  cycle) cmd_cycle ;;
  select) cmd_select ;;
  set) cmd_set "${2:?usage: power.sh set <profile>}" ;;
  *)
    echo "usage: $0 {status|pill|cycle|select|set <profile>}" >&2
    exit 1
    ;;
esac