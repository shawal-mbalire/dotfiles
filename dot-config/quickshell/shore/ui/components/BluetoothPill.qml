import QtQuick
import Quickshell.Bluetooth
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool adapterEnabled: adapter ? adapter.enabled : false
    readonly property int connected: adapter
        ? adapter.devices.values.filter(d => d.connected).length
        : 0

    icon: Theme.iconBluetooth
    iconColor: !adapterEnabled ? Theme.overlay0 : connected > 0 ? Theme.blue : Theme.subtext1
    text: connected > 0 ? String(connected) : ""

    // Both clicks open the device manager; power lives inside it as a switch so
    // it cannot be hit by accident from the bar.
    onClicked: UiState.toggleMenu("bluetooth")
    onSecondaryClicked: UiState.toggleMenu("bluetooth")
}
