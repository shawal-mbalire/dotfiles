pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../infra"

// Driven adapter: the Hyprland compositor (CompositorPort). Owns workspaces,
// monitor enumeration/configuration and session logout, so the UI and the idle
// adapter never import Quickshell.Hyprland or shell out to hyprctl themselves.
Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property int monitorCount: Hyprland.monitors.values.length
    readonly property bool focusedFullscreen: {
        const ws = Hyprland.focusedWorkspace;
        return ws ? ws.hasFullscreen : false;
    }

    property var monitors: []

    // ── CompositorPort ────────────────────────────────────────────────────
    function activateWorkspace(workspace) {
        if (workspace) workspace.activate();
    }

    function refreshMonitors() {
        if (!monitorsProc.running) monitorsProc.running = true;
    }

    function setMonitorDisabled(name, disabled) {
        const expr = disabled
            ? 'hl.monitor({ output = "' + name + '", disabled = true })'
            : 'hl.monitor({ output = "' + name + '", mode = "highres", '
                + 'position = "auto", scale = 1 })';
        evalProc.command = ["hyprctl", "eval", expr];
        evalProc.running = true;
    }

    function toggleMirror() {
        Quickshell.execDetached([Config.displayToggle]);
    }

    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(out.text) || [];
                } catch (e) {
                    root.monitors = [];
                }
            }
        }
    }

    Process {
        id: evalProc
        stdout: StdioCollector {}
        onExited: root.refreshMonitors()
    }
}
