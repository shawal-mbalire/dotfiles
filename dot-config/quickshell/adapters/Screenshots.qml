pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../domain"
import "../infra"

// Driven adapter: region screenshot persistence (ScreenshotsPort).
// Owns the output directory, file naming and clipboard copy so the overlay is
// pure interaction. The grab result is produced by the UI and handed here.
Singleton {
    id: root

    property string lastPath: ""
    property var _pendingGrab: null
    property string _pendingPath: ""

    // ── ScreenshotsPort ───────────────────────────────────────────────────
    function capture(grabResult) {
        if (!grabResult) return;
        root._pendingGrab = grabResult;
        root._pendingPath = InfraConfig.home + "/" + Constants.screenshotDir
            + "/shot-" + Date.now() + ".png";
        mkdirProc.running = true;
    }

    function copyToClipboard(path) {
        if (!path) return;
        Clipboard.write(path);
    }

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", InfraConfig.home + "/" + Constants.screenshotDir]
        onExited: {
            if (!root._pendingGrab) return;
            root._pendingGrab.saveToFile(root._pendingPath);
            root._pendingGrab = null;
            root.lastPath = root._pendingPath;
            root.copyToClipboard(root.lastPath);
        }
    }
}
