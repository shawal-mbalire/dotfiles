import QtQuick
import Quickshell.Services.UPower
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool present: battery && battery.isPresent
    readonly property int pct: battery ? Formatters.percent(battery.percentage) : 0
    readonly property bool charging: battery
        && (battery.state === UPowerDeviceState.Charging
            || battery.state === UPowerDeviceState.FullyCharged)

    visible: present
    icon: Theme.iconBattery
    iconColor: charging ? Theme.teal
             : pct <= Constants.batteryCritical ? Theme.red
             : pct <= Constants.batteryLow ? Theme.yellow
             : Theme.green
    text: present ? pct + "%" : ""
}
