import QtQuick
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

Pill {
    id: root

    icon: Theme.iconNight
    iconColor: Nightlight.active ? Theme.pink : Theme.overlay0
    text: Nightlight.active ? "on" : "off"
    textColor: Nightlight.active ? Theme.pink : Theme.overlay0

    onClicked: UiState.toggleMenu("display")
    onSecondaryClicked: UiState.toggleMenu("display")
}
