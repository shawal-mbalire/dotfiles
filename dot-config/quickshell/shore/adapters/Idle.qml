pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../domain"

// Driven adapter: idle detection via ext-idle-notify. Emits when the session
// has been idle long enough to lock or suspend; the composition root decides
// what to do. Replaces hypridle.
//
// Idle only ever fires when nothing is being watched: media playing (MPRIS)
// or a fullscreen window on the focused workspace means the session is treated
// as always-active, so the idle timer is paused entirely.
Singleton {
    id: root

    // Set false to pause idle handling (e.g. while locked).
    property bool enabled: true

    readonly property bool mediaPlaying: {
        const players = Mpris.players.values;
        for (const player of players)
            if (player.isPlaying) return true;
        return false;
    }

    readonly property bool fullscreenActive: Compositor.focusedFullscreen

    readonly property bool active: enabled && !mediaPlaying && !fullscreenActive
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
