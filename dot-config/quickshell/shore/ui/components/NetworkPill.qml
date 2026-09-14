import QtQuick
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    readonly property string wiredName: Network.wiredDevice ? Network.wiredDevice.name : ""
    readonly property int signalPercent: Network.wireless ? Formatters.percent(Network.signal) : 0

    icon: Network.wiredConnected ? Theme.iconWired : Theme.iconNetwork
    iconColor: Network.connected ? Theme.lavender : Theme.overlay0
    text: Network.wiredConnected ? wiredName
        : Network.wireless ? signalPercent + "%"
        : "offline"

    // left: Wi-Fi menu, right: control center
    onClicked: UiState.toggleMenu("wifi")
    onSecondaryClicked: UiState.toggleControlCenter()
}
