pragma Singleton

import QtQuick
import Quickshell

// Driven adapter: session power actions (SessionPort) via systemd/logind.
// Keeps the shell from shelling out to systemctl inline. Logout belongs to the
// compositor and lives in the Compositor adapter.
Singleton {
    id: root

    // ── SessionPort ───────────────────────────────────────────────────────
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
