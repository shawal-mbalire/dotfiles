pragma Singleton

import QtQuick
import Quickshell

// Domain: time source for measuring operation duration (TimePort).
// Pure wrapper over the clock so it can be swapped/faked.
Singleton {
    function nowMs() {
        return Date.now();
    }

    function elapsedMs(startMs) {
        return Date.now() - startMs;
    }
}
