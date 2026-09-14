#!/usr/bin/env bash
# Make greetd the display manager, replacing gdm.
#
# gdm is disabled but not stopped, so your current session keeps running until
# you reboot. If the greeter does not come up after the reboot, recover from a
# text console (Ctrl+Alt+F3) with:
#   sudo systemctl enable --now gdm    # or: sudo systemctl disable greetd
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "run as root: sudo $0" >&2
    exit 1
fi

if ! rpm -q greetd >/dev/null 2>&1; then
    echo "greetd is not installed; run setup/install.sh first" >&2
    exit 1
fi

echo "==> disabling gdm (current session keeps running)"
systemctl disable gdm

echo "==> enabling greetd as the display manager"
systemctl enable greetd

echo
echo "Done. Reboot to log in through the Quickshell greeter."
