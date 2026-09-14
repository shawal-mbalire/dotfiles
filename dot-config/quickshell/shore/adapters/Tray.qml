pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Driven adapter: the system tray (TrayPort). Items stay reactive handles; all
// interactions are methods so the UI never imports Quickshell.Services.SystemTray.
Singleton {
    id: root

    readonly property var items: SystemTray.items.values

    // ── TrayPort ──────────────────────────────────────────────────────────
    function activate(item) {
        if (item) item.activate();
    }

    function secondaryActivate(item) {
        if (item) item.secondaryActivate();
    }

    function display(item, parent, x, y) {
        if (item && item.hasMenu) item.display(parent, x, y);
    }

    function scroll(item, deltaY, horizontal) {
        if (item) item.scroll(deltaY, horizontal);
    }
}
