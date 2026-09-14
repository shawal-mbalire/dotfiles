pragma Singleton

import QtQuick
import Quickshell
import "../domain"

// Driven adapter: derive the accent palette from the login wallpaper, so the
// prompt, selection highlights and session picker retint to match the desktop.
// Same selection logic as shore's WallpaperColors, minus the cache/prefetch
// (the greeter only ever shows one image).
Singleton {
    id: root

    property color _accent: Theme.blue
    property bool _ready: false

    readonly property color accent: root._ready ? root._accent : Theme.blue
    readonly property color accentAlt: Qt.lighter(accent, 1.25)

    function normalize(c) {
        if (c.hsvValue < 0.55) return Qt.lighter(c, 1.6);
        return c;
    }

    function pick(colors) {
        let best = Theme.blue;
        if (!colors || colors.length === 0) return best;
        let bestScore = -1;
        for (const c of colors) {
            const sat = c.hsvSaturation;
            const val = c.hsvValue;
            if (val < 0.3 || val > 0.95) continue;
            const score = sat * (1 - Math.abs(val - 0.65));
            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }
        return best;
    }

    ColorQuantizer {
        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        depth: 3
        rescaleSize: 48

        onColorsChanged: {
            if (colors.length > 0) {
                root._accent = root.normalize(root.pick(colors));
                root._ready = true;
            }
        }
    }
}
