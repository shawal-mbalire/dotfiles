pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Driven adapter: clipboard history via cliphist.
// Implements the ClipboardPort (refresh / copy / remove / wipe).
Singleton {
    id: root

    property var items: []

    function refresh() {
        if (!listProc.running) listProc.running = true;
    }

    function copy(line) {
        copyProc.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", line];
        copyProc.running = true;
    }

    function remove(line) {
        removeProc.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", line];
        removeProc.running = true;
    }

    function wipe() {
        root.items = [];
        if (listProc.running) listProc.running = false;
        if (!wipeProc.running) wipeProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const text = out.text.trim();
                root.items = text === "" ? [] : text.split("\n");
            }
        }
    }

    Process {
        id: copyProc
        onExited: root.refresh()
    }

    Process {
        id: removeProc
        onExited: root.refresh()
    }

    Process {
        id: wipeProc
        onExited: root.refresh()
    }
}
