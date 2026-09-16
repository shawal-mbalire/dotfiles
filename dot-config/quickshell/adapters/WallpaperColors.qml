pragma Singleton

import QtQuick
import Quickshell
import "../domain"

// Driven adapter: derive an accent palette from the current wallpaper.
//
// Performance: ColorQuantizer decodes the whole JPEG synchronously, which costs
// ~100ms on a 4K photo and would blow the 25-50ms operation budget. So accents
// are computed by a background prefetcher, one image at a time, with a cooldown
// between each. The current wallpaper is quantized first; reading the accent is
// then a cache hit (0ms) and toggling never blocks on decoding.
Singleton {
    id: root

    property var _cache: ({})
    property int _revision: 0
    property string _pending: ""

    readonly property color accent: {
        root._revision; // re-evaluate when the cache grows
        const hit = root._cache[Wallpaper.current];
        return hit !== undefined ? hit : Theme.blue;
    }

    readonly property color accentAlt: Qt.lighter(accent, 1.25)

    Connections {
        target: Wallpaper
        function onImagesChanged() {
            root.pump();
        }
        function onCurrentChanged() {
            root.pump();
        }
    }

    Component.onCompleted: pump()

    // Prefer the current wallpaper, then the rest of the set.
    function ordered() {
        const current = Wallpaper.current;
        const images = Wallpaper.images.slice();
        images.sort((a, b) => a === current ? -1 : b === current ? 1 : 0);
        return images;
    }

    function pump() {
        if (root._pending !== "") return;
        for (const path of root.ordered()) {
            if (root._cache[path] === undefined) {
                root._pending = path;
                quantizer.source = "file://" + path;
                return;
            }
        }
    }

    Timer {
        id: cooldown
        interval: 150
        onTriggered: root.pump()
    }

    ColorQuantizer {
        id: quantizer
        source: ""
        depth: 3
        rescaleSize: 48

        onColorsChanged: {
            if (root._pending !== "" && quantizer.colors.length > 0) {
                const next = Object.assign({}, root._cache);
                next[root._pending] = Formatters.normalizeAccent(Formatters.pickAccent(quantizer.colors, Theme.blue));
                root._cache = next;
                root._revision++;
            }
            root._pending = "";
            cooldown.restart();
        }
    }
}
