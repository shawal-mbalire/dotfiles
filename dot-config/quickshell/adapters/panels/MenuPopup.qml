import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../../domain"

// Bar submenu host. One PanelWindow whose content is swapped by a Loader, so
// only the active menu exists. Opened by the pill clicks, not by fuzzel.
LazyLoader {
    id: loader
    active: UiState.activeMenu !== ""

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        // Start below the bar so the bar pills stay clickable while a menu is
        // open (clicking another pill switches menus instead of just closing).
        margins.top: Theme.barHeight
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Close on any click outside the card
        MouseArea {
            anchors.fill: parent
            focus: true
            onClicked: UiState.closePanels()
            // Close on Escape
            Keys.onEscapePressed: UiState.closePanels()
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.rightMargin: 8
            implicitWidth: 320
            implicitHeight: menuLoader.implicitHeight + 24
            radius: Theme.radius
            color: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.35)

            opacity: 0

            Component.onCompleted: {
                opacity = 1;
            }

            Behavior on opacity {
                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
            }

            // Left vertical bar
            Rectangle {
                width: 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Theme.radius
                anchors.bottomMargin: Theme.radius
                color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.25)
            }

            // Right vertical bar
            Rectangle {
                width: 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.topMargin: Theme.radius
                anchors.bottomMargin: Theme.radius
                color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.25)
            }

            // Prevent clicks inside the card from propagating to the backdrop
            MouseArea {
                anchors.fill: parent
            }

            Loader {
                id: menuLoader
                asynchronous: true
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                source: {
                    switch (UiState.activeMenu) {
                        case "connectivity": return "../components/ConnectivityMenu.qml";
                        case "wifi": return "../components/ConnectivityMenu.qml";
                        case "bluetooth": return "../components/ConnectivityMenu.qml";
                        case "media": return "../components/AudioMenu.qml";
                        case "audio": return "../components/AudioMenu.qml";
                        case "power": return "../components/PowerMenu.qml";
                        case "display": return "../components/DisplayMenu.qml";
                        case "system": return "../components/SystemMenu.qml";
                        default: return "";
                    }
                }
            }
        }
    }
}
