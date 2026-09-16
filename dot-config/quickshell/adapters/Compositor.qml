pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../domain"
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
        Quickshell.execDetached([InfraConfig.displayToggle]);
    }

    function setScale(scale) {
        const name = monitors.length > 0 ? monitors[0].name : "eDP-1";
        const mon = monitors.find(m => m.name === name);
        const mode = mon ? mon.width + "x" + mon.height + "@" + mon.refreshRate.toFixed(0) : "1920x1200@60";
        evalProc.command = ["hyprctl", "keyword", "monitor",
            name + "," + mode + ",0x0," + String(scale)];
        evalProc.running = true;
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
