pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../domain"
import "../infra"

// Gammastep night light. The existing waybar hexagon owns gammastep lifecycle
// (start/stop with the configured temperature), so we delegate to it.
Singleton {
    id: root

    readonly property int defaultTemp: 16000
    readonly property int nightTemp: 3500
    property bool active: false
    property int temperature: nightTemp

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

    function step(delta) {
        temperature = Math.max(1000, Math.min(6500, temperature + delta));
        if (active) {
            Quickshell.execDetached(["pkill", "-f", "gammastep"]);
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 200
        onTriggered: Quickshell.execDetached([
            "gammastep", "-O", String(temperature)
        ])
    }

    Process {
        id: statusProc
        command: [InfraConfig.python, "-S", InfraConfig.helper, "nightlight", "status"]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: root.active = statusOut.text.trim() === "On"
        }
    }

    Process {
        id: toggleProc
        command: [InfraConfig.python, "-S", InfraConfig.helper, "nightlight", "toggle"]
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
