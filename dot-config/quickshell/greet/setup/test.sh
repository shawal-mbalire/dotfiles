#!/usr/bin/env bash
# Run greetd on a spare VT (7) with the current display manager still active,
# so a broken greeter costs a switch back to another VT rather than a rescue.
#
# Switch to it with Ctrl+Alt+F7, log in for real, then Ctrl+C here to stop.
# This must be a genuinely free VT: check `loginctl list-sessions` first.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "run as root: sudo $0" >&2
    exit 1
fi

CONF="$(mktemp /tmp/greetd-test.XXXXXX.toml)"
cat > "$CONF" <<'EOF'
[terminal]
vt = 7

[default_session]
command = "cage -s -- qs -c greet"
user = "greetd"
EOF

echo "greetd test config: $CONF (vt 7)"
echo "press Ctrl+Alt+F7 to test; Ctrl+C here to stop"
exec greetd --config "$CONF"
