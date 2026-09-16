pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../domain"

// Driven adapter: power state (BatteryPort) over UPower.
// Owns battery state and power profiles so the UI never imports UPower. The
// service's state enums are mapped here; the domain only sees booleans/percent.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: root.device ? root.device.isPresent : false
    readonly property bool ready: root.device ? root.device.ready : false
    readonly property real percentage: root.device ? root.device.percentage : 0
    readonly property int percent: Formatters.percent(root.percentage)

    readonly property bool charging: root.device
        && (root.device.state === UPowerDeviceState.Charging
            || root.device.state === UPowerDeviceState.FullyCharged
            || root.device.state === UPowerDeviceState.PendingCharge)

    readonly property int profile: PowerProfiles.profile
    readonly property string profileLabel: PowerProfile.toString(root.profile)
    readonly property var profiles: [
        { label: "Power Saver", value: PowerProfile.PowerSaver },
        { label: "Balanced", value: PowerProfile.Balanced },
        { label: "Performance", value: PowerProfile.Performance }
    ]

    // ── BatteryPort ───────────────────────────────────────────────────────
    function setProfile(value) {
        PowerProfiles.profile = value;
    }
}
