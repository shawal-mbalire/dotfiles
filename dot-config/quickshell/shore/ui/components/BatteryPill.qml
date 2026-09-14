import QtQuick
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    readonly property bool present: Battery.present
    readonly property int pct: Battery.percent
    readonly property bool charging: Battery.charging

    visible: present
    icon: Theme.iconBattery
    iconColor: charging ? Theme.teal
             : pct <= Constants.batteryCritical ? Theme.red
             : pct <= Constants.batteryLow ? Theme.yellow
             : Theme.green
    text: present ? pct + "%" : ""
}
