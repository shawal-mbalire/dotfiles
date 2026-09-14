pragma Singleton

import QtQuick
import Quickshell
import "../domain"

// Driven adapter: derive an accent palette from the current wallpaper via
// ColorQuantizer. Falls back to the static Catppuccin accent when no wallpaper
// or no usable colour is found.
Singleton {
    id: root

    readonly property var source: Wallpaper.current
    readonly property color accent: normalize(pick(quantizer.colors))
    readonly property color accentAlt: Qt.lighter(accent, 1.25)

    // Keep the accent bright enough to read as a highlight on dark surfaces.
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
            // Prefer vivid colours that aren't near-black or near-white.
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
        id: quantizer
        source: root.source !== "" ? "file://" + root.source : ""
        depth: 2
    }
}
