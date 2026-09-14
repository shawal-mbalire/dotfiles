import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Bar submenu host. One PanelWindow whose content is swapped by a Loader, so
// only the active menu exists. Opened by the pill clicks, not by fuzzel.
LazyLoader {
    id: loader
    active: UiState.activeMenu !== ""

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.barHeight + 4
            right: 8
        }
        implicitWidth: 320
        implicitHeight: card.implicitHeight
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: menuLoader.implicitHeight + 24
            radius: Theme.radius
            color: Theme.tint(Theme.mantle, 0.97)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.6)

            Loader {
                id: menuLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                source: {
                    switch (UiState.activeMenu) {
                        case "bluetooth": return "../components/BluetoothMenu.qml";
                        case "wifi": return "../components/WifiMenu.qml";
                        case "audio": return "../components/AudioMenu.qml";
                        case "power": return "../components/PowerMenu.qml";
                        case "display": return "../components/DisplayMenu.qml";
                        default: return "";
                    }
                }
            }
        }
    }
}
