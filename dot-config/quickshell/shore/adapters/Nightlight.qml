pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../infra"

// Gammastep night light. The existing waybar hexagon owns gammastep lifecycle
// (start/stop with the configured temperature), so we delegate to it.
Singleton {
    id: root

    property bool active: false

    function refresh() {
        if (!statusProc.running) statusProc.running = true;
    }

    function toggle() {
        if (toggleProc.running) return;
        // Optimistic: reflect the new state immediately so the bar is reactive.
        // refresh() on exit reconciles with the actual gammastep process.
        root.active = !root.active;
        toggleProc.running = true;
    }

    Process {
        id: statusProc
        command: [Config.python, "-S", Config.helper, "nightlight", "status"]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: root.active = statusOut.text.trim() === "On"
        }
    }

    Process {
        id: toggleProc
        command: [Config.python, "-S", Config.helper, "nightlight", "toggle"]
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
