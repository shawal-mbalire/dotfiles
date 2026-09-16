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

    implicitHeight: 48
    radius: Theme.radius
    color: connected ? Theme.tint(Theme.green, 0.85) : Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: connected ? Theme.tint(Theme.green, 0.85) : Theme.tint(Theme.surface1, 0.85)

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
            color: root.connected ? Theme.tint(Theme.green, 0.85) : Theme.tint(Theme.surface1, 0.85)

            Text {
                anchors.centerIn: parent
                text: Theme.iconBluetooth
                font.family: Theme.iconFontFamily
                font.pixelSize: 15
                color: root.connected ? Theme.green : Theme.subtext0
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
                color: root.connected ? Theme.green : Theme.subtext0
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
            label: "Forget"
            onClicked: Bluetooth.forgetDevice(root.device)
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
}
