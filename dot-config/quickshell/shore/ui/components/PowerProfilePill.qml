import QtQuick
import Quickshell.Services.UPower
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    readonly property string current: PowerProfile.toString(PowerProfiles.profile)

    icon: Theme.iconPower
    iconColor: current === "performance" ? Theme.red
             : current === "power-saver" ? Theme.blue
             : Theme.green
    text: current

    onClicked: UiState.toggleMenu("power")
    onSecondaryClicked: UiState.toggleMenu("power")
}
