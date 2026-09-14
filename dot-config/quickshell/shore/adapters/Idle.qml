pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../domain"

// Driven adapter: idle detection via ext-idle-notify. Emits when the session
// has been idle long enough to lock or suspend; the composition root decides
// what to do. Replaces hypridle.
Singleton {
    id: root

    // Set false to pause idle handling (e.g. while locked or inhibited).
    property bool enabled: true

    readonly property bool idle: lockMonitor.isIdle || suspendMonitor.isIdle

    signal lockRequested()
    signal suspendRequested()

    IdleMonitor {
        id: lockMonitor
        enabled: root.enabled
        timeout: Constants.idleLockSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockRequested()
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: root.enabled
        timeout: Constants.idleSuspendSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.suspendRequested()
    }
}
