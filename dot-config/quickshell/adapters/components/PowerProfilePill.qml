import QtQuick
import ".."
import "../../domain"
import "../../adapters"

Pill {
    id: root

    readonly property string current: Battery.profileLabel

    icon: Theme.iconPower
    iconColor: current === "performance" ? Theme.red
             : current === "power-saver" ? Theme.blue
             : Theme.green
    text: current

    onClicked: UiState.toggleMenu("power")
    onSecondaryClicked: UiState.toggleMenu("power")
}
