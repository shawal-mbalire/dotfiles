#!/usr/bin/env bash
# =============================================================================
# Domain: power-profile rules. Pure. No external commands, no I/O.
# The only place power-profile business knowledge lives.
# =============================================================================

# Static domain constants: known power profiles with their presentation
# metadata. Format: name|label|icon|class
# name  -> the power-profiles-daemon profile name (adapter-facing identifier)
# label -> human readable name shown in the UI
# icon  -> nerd-font glyph
# class -> waybar css class (which carries the accent color)
POWER_PROFILES=(
  "power-saver|Low power|󰾆|power-saver"
  "balanced|Balanced|󰝇|balanced"
  "performance|Performance|󰓅|performance"
)

POWER_PROFILE_FIELD_NAME=0
POWER_PROFILE_FIELD_LABEL=1
POWER_PROFILE_FIELD_ICON=2
POWER_PROFILE_FIELD_CLASS=3

# power_profile_names -> prints profile names in cycle order (one per line)
power_profile_names() {
  local entry
  for entry in "${POWER_PROFILES[@]}"; do
    printf '%s\n' "${entry%%|*}"
  done
}

# power_profile_field <name> <field_index> -> prints the requested field
power_profile_field() {
  local name="$1" idx="$2" entry
  for entry in "${POWER_PROFILES[@]}"; do
    IFS='|' read -r n label icon class <<< "$entry"
    if [[ "$n" == "$name" ]]; then
      case "$idx" in
        0) printf '%s\n' "$n" ;;
        1) printf '%s\n' "$label" ;;
        2) printf '%s\n' "$icon" ;;
        3) printf '%s\n' "$class" ;;
      esac
      return 0
    fi
  done
  return 1
}

# power_profile_exists <name> -> 0 if known, 1 otherwise
power_profile_exists() {
  local n
  while IFS= read -r n; do
    [[ "$n" == "$1" ]] && return 0
  done < <(power_profile_names)
  return 1
}

# power_next_profile <current> -> prints the next name in the cycle
power_next_profile() {
  local current="$1" n prev="" next="" first=""
  while IFS= read -r n; do
    [[ -z "$first" ]] && first="$n"
    if [[ "$prev" == "$current" ]]; then
      next="$n"
      break
    fi
    prev="$n"
  done < <(power_profile_names)
  [[ -z "$next" ]] && next="$first"
  printf '%s\n' "$next"
}

# power_default_profile -> prints the fallback profile name
power_default_profile() {
  printf '%s\n' "balanced"
}

# power_validate_current <candidate> -> prints a known profile, falling back
# to the default when the adapter reports an unknown name.
power_validate_current() {
  local candidate="${1:-}"
  if power_profile_exists "$candidate"; then
    printf '%s\n' "$candidate"
  else
    power_default_profile
  fi
}