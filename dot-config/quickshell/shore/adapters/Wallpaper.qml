pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../infra"

// Driven adapter: the wallpaper set. Scans Config.wallpaperDir for images and
// cycles through them. Implements the WallpaperPort (refresh / next / prev).
Singleton {
    id: root

    property var images: []
    property int index: 0

    readonly property string current: (images.length > 0 && index >= 0 && index < images.length)
        ? images[index]
        : Config.wallpaper

    function refresh() {
        if (!listProc.running) listProc.running = true;
    }

    function next() {
        if (images.length === 0) return;
        root.index = (root.index + 1) % images.length;
    }

    function prev() {
        if (images.length === 0) return;
        root.index = (root.index - 1 + images.length) % images.length;
    }

    // Mirror the current wallpaper to the greeter's shared location so the
    // login screen matches the desktop. Best-effort: failures (greeter not
    // installed, unwritable /var/lib/greetd) are ignored.
    function syncWallpaper() {
        if (root.current === "" || sync.running) return;
        sync._src = root.current;
        sync.running = true;
    }

    onCurrentChanged: syncWallpaper()

    Process {
        id: sync
        property string _src: ""
        command: ["sh", "-c",
            "{ cp -f -- \"$1\" \"$2\" && chmod 0640 -- \"$2\"; } 2>/dev/null || true",
            "sh", _src, Config.greeterWallpaper]
        // If the wallpaper changed while copying, run again with the new one.
        onExited: {
            if (root.current !== "" && root.current !== _src) {
                _src = root.current;
                running = true;
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            "find -L \"$1\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort",
            "sh", Config.wallpaperDir]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const text = out.text.trim();
                root.images = text === "" ? [] : text.split("\n");
                if (root.index >= root.images.length) root.index = 0;
            }
        }
    }

    Component.onCompleted: {
        refresh();
        syncWallpaper();
    }

    // Pick up images added to the folder while the shell is running.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
