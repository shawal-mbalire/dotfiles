import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../../domain"
import "../../infra"
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

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.tint(Theme.crust, 0.95) }
            GradientStop { position: 0.45; color: Theme.tint(Theme.base, 0.9) }
            GradientStop { position: 1.0; color: Theme.tint(Theme.mantle, 0.95) }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.tint(Theme.surface1, 0.55)
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
        NightlightPill {}
        NetworkPill {}
        PowerProfilePill {}
        AudioPill {}
        BacklightPill {}
        BatteryPill {}
        BluetoothPill {}
        TrayCluster {}
    }
}
