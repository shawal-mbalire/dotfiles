import QtQuick
import QtQuick.Layouts
import "../../domain"
import "../../adapters"

// Device row with a leading status badge, name, secondary status line and a
// single primary action. Right-click forgets a paired device.
Rectangle {
    id: root

    required property var device

    readonly property bool connected: device.connected
    readonly property bool paired: Formatters.isPaired(device)
    readonly property string status: connected ? "Connected"
        : paired ? ("Paired · " + device.address)
        : device.address

    property bool confirmingForget: false

    implicitHeight: Theme.menuWideRowHeight
    radius: Theme.radius
    color: connected ? Theme.tint(WallpaperColors.accent, 0.85)
         : btRowHover.pressed ? Theme.tint(Theme.surface0, 0.6)
         : btRowHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
         : Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: connected ? Theme.tint(WallpaperColors.accent, 0.85) : Theme.tint(Theme.surface1, 0.85)

    Behavior on color { ColorAnimation { duration: 80 } }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            color: root.connected ? Theme.tint(WallpaperColors.accent, 0.85) : Theme.tint(Theme.surface1, 0.85)

            Text {
                anchors.centerIn: parent
                text: Theme.iconBluetooth
                font.family: Theme.iconFontFamily
                font.pixelSize: 15
                color: root.connected ? WallpaperColors.accent : Theme.subtext0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: Formatters.btName(root.device, Bluetooth.nameCache)
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Theme.text
            }

            Text {
                Layout.fillWidth: true
                text: root.status
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: root.connected ? WallpaperColors.accent : Theme.subtext0
            }
        }

        Text {
            visible: root.device.batteryAvailable
            text: Formatters.percent(root.device.battery) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.subtext0
        }

        MenuButton {
            visible: root.paired
            label: root.confirmingForget ? "Confirm?" : "Forget"
            onClicked: {
                if (root.confirmingForget) {
                    root.confirmingForget = false;
                    Bluetooth.forgetDevice(root.device);
                } else {
                    root.confirmingForget = true;
                    confirmTimer.restart();
                }
            }
        }

        MenuButton {
            label: root.connected ? "Disconnect" : root.paired ? "Connect" : "Pair"
            onClicked: {
                if (root.connected) Bluetooth.disconnectDevice(root.device);
                else if (root.paired) Bluetooth.connectDevice(root.device);
                else Bluetooth.pairDevice(root.device);
            }
        }
    }

    Timer {
        id: confirmTimer
        interval: 2000
        onTriggered: root.confirmingForget = false
    }

    MouseArea {
        id: btRowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
