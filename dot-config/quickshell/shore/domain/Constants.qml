pragma Singleton

import QtQuick
import Quickshell

// Domain: named constants. Static business/domain knowledge only — no I/O.
Singleton {
    // WifiSecurityType enum values mirrored from Quickshell.Networking so the
    // pure domain can classify a network without importing the adapter.
    readonly property int securityOpen: 10
    readonly property int securityUnknown: 11

    // Battery presentation thresholds (percent).
    readonly property int batteryCritical: 15
    readonly property int batteryLow: 30

    // Volume step for scroll interaction (fraction).
    readonly property real volumeStep: 0.05

    // Brightness step for scroll/key interaction (percent points).
    readonly property int brightnessStep: 5
}
