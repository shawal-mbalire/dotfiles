pragma Singleton

import QtQuick
import Quickshell

// Driven adapter: application catalog for the launcher.
// Implements the LauncherPort (search / launch).
Singleton {
    id: root

    readonly property var applications: {
        const all = DesktopEntries.applications.values;
        return all.filter(e => e && e.name && !e.noDisplay);
    }

    function search(query) {
        const q = (query || "").trim().toLowerCase();
        const apps = root.applications;
        if (q === "") return apps.slice(0, 8);
        return apps.filter(e => {
            const hay = [e.name, e.genericName, e.comment,
                (e.keywords ? e.keywords.join(" ") : ""),
                (e.categories ? e.categories.join(" ") : "")].join(" ").toLowerCase();
            return hay.indexOf(q) !== -1;
        }).slice(0, 50);
    }

    function launch(entry) {
        if (entry) entry.execute();
    }
}
