pragma Singleton

import QtQuick
import Quickshell

// Ephemeral UI state shared across the bar, panels, menus and OSD.
// Kept intentionally free of system access so every surface can depend on it.
Singleton {
    id: root

    // ── Panels ────────────────────────────────────────────────────────────
    property bool controlCenterOpen: false
    property bool barVisible: true

    // Which bar submenu is open: "", "bluetooth", "audio", "power".
    property string activeMenu: ""

    // ── Session surfaces ──────────────────────────────────────────────────
    property bool locked: false
    property bool launcherOpen: false
    property string launcherMode: "apps"
    property bool screenshotOpen: false

    function lock() {
        controlCenterOpen = false;
        activeMenu = "";
        launcherOpen = false;
        screenshotOpen = false;
        locked = true;
    }

    function toggleLauncher(mode) {
        controlCenterOpen = false;
        activeMenu = "";
        launcherMode = mode ?? "apps";
        launcherOpen = !launcherOpen;
    }

    function closeLauncher() {
        launcherOpen = false;
    }

    function toggleScreenshot() {
        controlCenterOpen = false;
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
        controlCenterOpen = false;
        activeMenu = name;
    }

    function toggleMenu(name) {
        controlCenterOpen = false;
        activeMenu = activeMenu === name ? "" : name;
    }

    function toggleControlCenter() {
        activeMenu = "";
        controlCenterOpen = !controlCenterOpen;
    }

    function closePanels() {
        controlCenterOpen = false;
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
