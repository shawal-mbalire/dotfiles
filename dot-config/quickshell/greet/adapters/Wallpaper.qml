pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../infra"

// Driven adapter: the login screen's wallpaper. shore mirrors its current
// wallpaper to Config.wallpaper; this adapter resolves that path once at
// startup and leaves `current` empty when nothing has been synced yet, in
// which case the surface falls back to a solid theme colour.
Singleton {
    id: root

    property string current: ""

    function refresh() {
        if (!probe.running) probe.running = true;
    }

    Process {
        id: probe
        command: ["sh", "-c",
            "[ -r \"$1\" ] && printf '%s' \"$1\"", "sh", Config.wallpaper]
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
    }

    Component.onCompleted: refresh()
}
