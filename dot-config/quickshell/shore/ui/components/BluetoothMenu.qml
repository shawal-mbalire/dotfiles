import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter
        ? Formatters.sortBluetoothDevices(adapter.devices.values)
        : []
    readonly property var mine: devices.filter(d => d.connected || Formatters.isPaired(d))
    readonly property var available: devices.filter(d => !(d.connected || Formatters.isPaired(d)))

    implicitWidth: 300
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MenuTitle {
            title: "Bluetooth"
            subtitle: !root.adapter ? "No adapter"
                : root.adapter.enabled ? (root.adapter.name || "Adapter") + " · on"
                : "Off"
        }

        ToggleSwitch {
            checked: root.adapter ? root.adapter.enabled : false
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        visible: root.adapter && root.adapter.enabled
        radius: Theme.radius
        color: root.adapter && root.adapter.discovering
            ? Theme.tint(Theme.blue, 0.8)
            : Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.5)

        Text {
            anchors.centerIn: parent
            text: root.adapter && root.adapter.discovering ? "Scanning…" : "Scan for devices"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.adapter && root.adapter.discovering ? Theme.crust : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.adapter) root.adapter.discovering = !root.adapter.discovering
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.adapter && root.adapter.enabled && root.devices.length === 0
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
