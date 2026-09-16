import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// One bar per monitor. Instantiated by a Variants over Quickshell.screens.
// The clock is anchored to the window centre so it stays centred regardless of
// how wide the left/right groups grow.
PanelWindow {
    id: bar

    property var modelData
    screen: modelData
    visible: UiState.barVisible

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.tint(Theme.crust, 0.85) }
            GradientStop { position: 0.45; color: Theme.tint(Theme.base, 0.5) }
            GradientStop { position: 1.0; color: Theme.tint(Theme.mantle, 0.6) }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.tint(Theme.surface1, 0.85)
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.gap

        Workspaces {}
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.gap

        NotifBell {}
        TrayCluster {}

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.tint(Theme.surface1, 0.85) }

        GroupIcon {
            group: "connectivity"
            icon: Network.wiredConnected ? Theme.iconWired : Theme.iconNetwork
            iconColor: Network.connected ? Theme.lavender : Theme.overlay0
        }

        GroupIcon {
            group: "display"
            icon: Theme.iconDisplay
            iconColor: Nightlight.active ? Theme.pink : Theme.subtext1
        }

        GroupIcon {
            group: "media"
            icon: Theme.iconVolume
            iconColor: Theme.sapphire
        }
    }
}
