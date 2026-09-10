#!/usr/bin/env bash
# =============================================================================
# Driven adapter: power-profiles-daemon backend (system D-Bus) for the
# power-profile gateway. Reads/writes the ActiveProfile property via tuned-ppd,
# which is ~16x faster than `tuned-adm profile`.
# =============================================================================

PPD_BUS="net.hadess.PowerProfiles"
PPD_PATH="/net/hadess/PowerProfiles"
PPD_IFACE="net.hadess.PowerProfiles"

gateway_get_active() {
  busctl --system get-property "$PPD_BUS" "$PPD_PATH" "$PPD_IFACE" ActiveProfile 2>/dev/null |
    tr -d '"\n' | sed 's/^s //'
}

gateway_set_profile() { # $1 profile name
  busctl --system set-property "$PPD_BUS" "$PPD_PATH" "$PPD_IFACE" ActiveProfile s "$1" >/dev/null 2>&1
}