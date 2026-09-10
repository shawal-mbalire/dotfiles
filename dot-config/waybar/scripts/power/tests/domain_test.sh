#!/usr/bin/env bash
# =============================================================================
# Unit tests for the power-profile domain.
# Domain is pure, so tests need no I/O — only in-memory fakes.
# =============================================================================
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../domain.sh"

FAILED=0

assert_eq() { # $1 expected $2 actual $3 message
  if [[ "$1" != "$2" ]]; then
    printf 'FAIL: %s\n  expected: <%s>\n  actual:   <%s>\n' "$3" "$1" "$2"
    FAILED=1
  fi
}

assert_true() { # $1 message, cmd...
  local msg="$1"
  shift
  if ! "$@"; then
    printf 'FAIL: %s\n' "$msg"
    FAILED=1
  fi
}

# --- cycle order -------------------------------------------------------------
assert_eq "power-saver" "$(power_next_profile "performance")" "cycle wraps to first"
assert_eq "balanced" "$(power_next_profile "power-saver")" "cycle power-saver -> balanced"
assert_eq "performance" "$(power_next_profile "balanced")" "cycle balanced -> performance"

# --- metadata ----------------------------------------------------------------
assert_eq "󰝇" "$(power_profile_field "balanced" "$POWER_PROFILE_FIELD_ICON")" "balanced icon"
assert_eq "Performance" "$(power_profile_field "performance" "$POWER_PROFILE_FIELD_LABEL")" "performance label"
assert_eq "power-saver" "$(power_profile_field "power-saver" "$POWER_PROFILE_FIELD_CLASS")" "power-saver class"

# --- validation --------------------------------------------------------------
assert_eq "balanced" "$(power_validate_current "")" "empty candidate falls back to default"
assert_eq "balanced" "$(power_validate_current "not-a-real-profile")" "unknown profile falls back to default"
assert_eq "balanced" "$(power_validate_current "balanced")" "known profile passes through"

# --- existence ---------------------------------------------------------------
assert_true "balanced is a known profile" power_profile_exists "balanced"
if power_profile_exists "bogus"; then
  printf 'FAIL: unknown profile is rejected\n'
  FAILED=1
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "domain: all tests passed"
else
  echo "domain: TESTS FAILED" >&2
  exit 1
fi