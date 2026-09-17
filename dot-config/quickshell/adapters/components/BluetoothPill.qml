import QtQuick
import ".."
import "../../domain"
import "../../adapters"

Pill {
    id: root

    icon: Theme.iconBluetooth
    iconColor: !Bluetooth.enabled ? Theme.overlay0
             : Bluetooth.connectedCount > 0 ? Theme.blue
             : Theme.subtext1
    text: Bluetooth.connectedCount > 0 ? String(Bluetooth.connectedCount) : ""

    // Both clicks open the device manager; power lives inside it as a switch so
    // it cannot be hit by accident from the bar.
    onClicked: UiState.toggleMenu("connectivity")
    onSecondaryClicked: UiState.toggleMenu("connectivity")
}
