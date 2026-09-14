pragma Singleton

import QtQuick
import Quickshell

// Ports: adapter contracts, verified at the composition root so a drifted
// adapter fails loud instead of misbehaving at runtime.
Singleton {
    function hasMethods(adapter, names) {
        if (!adapter) return false;
        for (const name of names)
            if (typeof adapter[name] !== "function") return false;
        return true;
    }

    function assertPort(adapter, names, portName) {
        if (!adapter)
            throw new Error("Adapter for " + portName + " is missing");
        for (const name of names) {
            if (typeof adapter[name] !== "function")
                throw new Error("Adapter does not implement " + portName + ":" + name);
        }
        return true;
    }

    function assertPorts(specs) {
        for (const spec of specs)
            assertPort(spec.adapter, spec.methods, spec.name);
        return true;
    }

    // Contracts (documented for readers).
    readonly property var brightnessPort: ["refresh", "setPercent", "step"]
    readonly property var nightlightPort: ["refresh", "toggle"]
    readonly property var networkPort: ["setWifi", "toggleWifi"]
    readonly property var notificationsPort: ["toggleDnd", "dismissAll", "closePopup", "notify"]
    readonly property var polkitPort: ["submit", "cancel"]
    readonly property var launcherPort: ["search", "launch"]
    readonly property var clipboardPort: ["refresh", "copy", "remove", "wipe"]
    readonly property var wallpaperPort: ["refresh", "next", "prev"]
}
