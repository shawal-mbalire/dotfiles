pragma Singleton

import QtQuick
import Quickshell

// Domain: port contracts — the 16 adapter interfaces this shell requires.
// Assertion logic lives in infra/verify.qml; these are the documented
// method lists that each adapter must implement.
Singleton {
    readonly property var audioPort: ["setDefaultSink", "setDefaultSource", "toggleMute", "setVolume", "bumpVolume", "openTweaker"]
    readonly property var authPort: ["start", "submit"]
    readonly property var batteryPort: ["setProfile"]
    readonly property var bluetoothPort: ["setEnabled", "toggle", "setDiscovering", "toggleDiscovering", "connectDevice", "disconnectDevice", "pairDevice", "forgetDevice"]
    readonly property var brightnessPort: ["refresh", "setPercent", "step"]
    readonly property var clipboardPort: ["refresh", "copy", "remove", "wipe"]
    readonly property var compositorPort: ["activateWorkspace", "refreshMonitors", "setMonitorDisabled", "toggleMirror", "logout"]
    readonly property var launcherPort: ["search", "launch"]
    readonly property var mediaPort: ["previous", "next", "togglePlaying"]
    readonly property var networkPort: ["setWifi", "toggleWifi", "setScanner", "toggleScanner", "connectNetwork", "disconnectNetwork", "forgetNetwork", "connectWithPsk"]
    readonly property var nightlightPort: ["refresh", "toggle"]
    readonly property var notificationsPort: ["toggleDnd", "dismissAll", "closePopup", "notify"]
    readonly property var screenshotsPort: ["capture", "copyToClipboard"]
    readonly property var sessionPort: ["suspend", "reboot", "poweroff"]
    readonly property var trayPort: ["activate", "secondaryActivate", "display", "scroll"]
    readonly property var wallpaperPort: ["refresh", "next", "prev"]
}
