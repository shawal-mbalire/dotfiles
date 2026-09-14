#!/usr/bin/env bash
# Install the Quickshell login greeter on Fedora (greetd + cage).
#
# Prepares everything but does NOT touch the display manager: try it first with
# setup/test.sh on a spare VT, then make it permanent with setup/switch.sh.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
GREET_DIR="$(dirname -- "$SCRIPT_DIR")"
TARGET="/etc/xdg/quickshell/greet"
# Desktop account that owns the shared wallpaper. Override with GREET_USER=...
USER_NAME="${GREET_USER:-${SUDO_USER:-$(id -un)}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

if [ "$(id -u)" -ne 0 ]; then
    echo "run as root: sudo $0" >&2
    exit 1
fi

if ! command -v qs >/dev/null 2>&1; then
    echo "quickshell (qs) not found; install it before this greeter" >&2
    exit 1
fi

echo "==> installing greetd, cage and fprintd"
dnf install -y greetd cage fprintd-pam

echo "==> granting the greeter user GPU/seat access"
usermod -aG video greetd
if getent group render >/dev/null 2>&1; then
    usermod -aG render greetd
fi

echo "==> publishing the greeter to $TARGET (readable by the greetd user)"
# The greeter runs as `greetd`, whose home is /var/lib/greetd, so ~/.config is
# not visible. /etc/xdg is on Quickshell's XDG config search path.
install -d -m 0755 "$TARGET"
for d in domain infra ports adapters ui; do
    install -d -m 0755 "$TARGET/$d"
    install -m 0644 "$GREET_DIR/$d"/* "$TARGET/$d/"
done
install -m 0644 "$GREET_DIR/shell.qml" "$TARGET/shell.qml"

echo "==> preparing the shared wallpaper directory"
install -d -m 0755 /var/lib/greetd
# setgid so files copied in by the desktop user inherit the `greetd` group
install -d -o "$USER_NAME" -g greetd -m 2750 /var/lib/greetd/wallpaper

echo "==> seeding the shared wallpaper from $USER_HOME/wallpapers"
if [ -r "$USER_HOME/wallpapers/wallpaper.jpg" ]; then
    install -o "$USER_NAME" -g greetd -m 0640 \
        "$USER_HOME/wallpapers/wallpaper.jpg" /var/lib/greetd/wallpaper/current
fi

echo "==> writing /etc/greetd/config.toml"
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
# cage is a kiosk: it exits when the greeter exits, handing the seat back to
# greetd. -s allows VT switching so a hung greeter can still be escaped with
# Ctrl+Alt+F3.
command = "cage -s -- qs -c greet"
user = "greetd"
EOF

echo "==> enabling fingerprint at login"
# greetd authenticates through /etc/pam.d/greetd, which pulls system-auth.
# authselect already puts `pam_fprintd` there, so fingerprint works out of the
# box; only patch greetd's stack if the system stack lacks it.
if grep -qs pam_fprintd /etc/pam.d/system-auth /etc/pam.d/greetd; then
    echo "    fingerprint already available via PAM"
elif [ -f /etc/pam.d/greetd ]; then
    sed -i '0,/^auth[[:space:]]/s/^auth[[:space:]]/auth       sufficient   pam_fprintd.so\nauth       /' \
        /etc/pam.d/greetd
    echo "    added pam_fprintd to /etc/pam.d/greetd"
fi

echo
echo "Installed. Next:"
echo "  test on a spare VT (gdm stays in charge):  sudo $SCRIPT_DIR/test.sh"
echo "  make it permanent:                         sudo $SCRIPT_DIR/switch.sh"
