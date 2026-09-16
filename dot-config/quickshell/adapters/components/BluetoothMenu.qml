import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

ColumnLayout {
    id: root

    readonly property var mine: Bluetooth.pairedDevices
    readonly property var available: Bluetooth.otherDevices

    implicitWidth: 300
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MenuTitle {
            title: "Bluetooth"
            subtitle: !Bluetooth.available ? "No adapter"
                : Bluetooth.enabled ? (Bluetooth.name || "Adapter") + " · on"
                : "Off"
        }

        ToggleSwitch {
            checked: Bluetooth.enabled
            onToggled: Bluetooth.toggle()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        visible: Bluetooth.available && Bluetooth.enabled
        radius: Theme.radius
        color: Bluetooth.discovering
            ? Theme.tint(WallpaperColors.accent, 0.85)
            : Theme.tint(Theme.surface0, 0.85)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.85)

        Text {
            anchors.centerIn: parent
            text: Bluetooth.discovering ? "Scanning…" : "Scan for devices"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Bluetooth.discovering ? Theme.crust : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Bluetooth.toggleDiscovering()
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Bluetooth.available && Bluetooth.enabled && Bluetooth.devices.length === 0
        text: "No devices yet — scan to find some"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.mine.length > 0
        spacing: 6

        SectionLabel { label: "My devices" }

        Repeater {
            model: root.mine
            BluetoothDeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.available.length > 0
        spacing: 6

        SectionLabel { label: "Available" }

        Repeater {
            model: root.available
            BluetoothDeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }
}
