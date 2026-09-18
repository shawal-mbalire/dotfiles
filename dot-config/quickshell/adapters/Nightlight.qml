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
    property bool active: false
    property int temperature: defaultTemp

    function refresh() {
        if (!statusProc.running) statusProc.running = true;
    }

    function toggle() {
        if (statusProc.running) return;
        statusProc._pendingToggle = true;
        statusProc.running = true;
    }

    function start() {
        Quickshell.execDetached(["gammastep", "-O", String(defaultTemp)]);
        root.active = true;
    }

    function stop() {
        Quickshell.execDetached(["pkill", "-f", "gammastep"]);
        root.active = false;
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
        property bool _pendingToggle: false
        command: ["pgrep", "-x", "gammastep"]
        stdout: StdioCollector {}
        onExited: {
            root.active = exitCode === 0;
            if (_pendingToggle) {
                _pendingToggle = false;
                if (exitCode === 0) root.stop();
                else root.start();
            }
        }
    }

    Timer {
        interval: 10000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
