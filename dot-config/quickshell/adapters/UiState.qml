pragma Singleton

import QtQuick
import Quickshell

// Ephemeral UI state shared across the bar, panels, menus and OSD.
// Kept intentionally free of system access so every surface can depend on it.
Singleton {
    id: root

    // ── Panels ────────────────────────────────────────────────────────────
    property bool barVisible: true

    // Which bar submenu is open: "", "connectivity", "audio", "power", "display", "system".
    property string activeMenu: ""

    // ── Session surfaces ──────────────────────────────────────────────────
    property bool locked: false
    property bool launcherOpen: false
    property string launcherMode: "apps"
    property bool screenshotOpen: false

    function lock() {
        activeMenu = "";
        launcherOpen = false;
        screenshotOpen = false;
        locked = true;
    }

    function toggleLauncher(mode) {
        activeMenu = "";
        launcherMode = mode ?? "apps";
        launcherOpen = !launcherOpen;
    }

    function closeLauncher() {
        launcherOpen = false;
    }

    function toggleScreenshot() {
        activeMenu = "";
        screenshotOpen = !screenshotOpen;
    }

    function closeScreenshot() {
        screenshotOpen = false;
    }

    function toggleBar() {
        barVisible = !barVisible;
    }

    function openMenu(name) {
        activeMenu = name;
    }

    function toggleMenu(name) {
        activeMenu = activeMenu === name ? "" : name;
    }

    function closePanels() {
        activeMenu = "";
    }

    // ── On-screen display ─────────────────────────────────────────────────
    property bool osdVisible: false
    property string osdIcon: "audio-volume-high-symbolic"
    property real osdValue: 0
    property string osdLabel: ""

    function showOsd(icon, value, label) {
        osdIcon = icon;
        osdValue = Math.max(0, Math.min(1, value));
        osdLabel = label ?? "";
        osdVisible = true;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1400
        onTriggered: root.osdVisible = false
    }
}
