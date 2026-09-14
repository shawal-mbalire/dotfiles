pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../domain"

// Driven adapter: idle detection via ext-idle-notify. Emits when the session
// has been idle long enough to lock or suspend; the composition root decides
// what to do. Replaces hypridle.
Singleton {
    id: root

    // Set false to pause idle handling (e.g. while locked).
    property bool enabled: true

    // Don't count time spent watching/playing media as idle. MPRIS covers
    // browsers (YouTube etc.); respectInhibitors covers native players.
    readonly property bool mediaPlaying: {
        const players = Mpris.players.values;
        for (const player of players)
            if (player.isPlaying) return true;
        return false;
    }

    readonly property bool active: enabled && !mediaPlaying
    readonly property bool idle: lockMonitor.isIdle || suspendMonitor.isIdle

    signal lockRequested()
    signal suspendRequested()

    IdleMonitor {
        id: lockMonitor
        enabled: root.active
        timeout: Constants.idleLockSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockRequested()
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: root.active
        timeout: Constants.idleSuspendSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.suspendRequested()
    }
}
