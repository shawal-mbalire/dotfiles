import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

// Connectivity group: Wi-Fi + Bluetooth in one menu.
BaseMenu {
    id: root

    // ── Wi-Fi ────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MenuTitle {
            title: "Wi-Fi"
            subtitle: !Network.wifiDevice ? "No device"
                : Network.wifiEnabled ? (Network.wifiDevice.name || "On")
                : "Off"
        }

        ToggleSwitch {
            checked: Network.wifiEnabled
            onToggled: Network.toggleWifi()
        }
    }

    Rectangle {
        id: wifiScan
        Layout.fillWidth: true
        implicitHeight: Theme.menuCompactRowHeight
        visible: Network.wifiDevice && Network.wifiEnabled
        radius: Theme.radius
        color: Network.wifiScanning
            ? Theme.tint(WallpaperColors.accent, 0.85)
            : wifiScanHover.pressed ? Theme.tint(Theme.surface0, 0.6)
            : wifiScanHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
            : Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.85)

        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text: Network.wifiScanning ? "Scanning…" : "Scan for networks"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Network.wifiScanning ? Theme.crust : Theme.text
        }

        MouseArea {
            id: wifiScanHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Network.toggleScanner()
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Network.wifiDevice && Network.wifiEnabled && Network.wifiNetworks.length === 0
        text: "No networks — scan to find some"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }

    ListView {
        Layout.fillWidth: true
        visible: Network.wifiNetworks.length > 0
        implicitHeight: Math.min(contentHeight, 160)
        model: Network.wifiNetworks
        spacing: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: WifiNetworkRow {
            required property var modelData
            width: ListView.view.width
            network: modelData
        }
    }


    // ── Bluetooth ────────────────────────────────────────────────────────
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
        id: btScan
        Layout.fillWidth: true
        implicitHeight: Theme.menuCompactRowHeight
        visible: Bluetooth.available && Bluetooth.enabled
        radius: Theme.radius
        color: Bluetooth.discovering
            ? Theme.tint(WallpaperColors.accent, 0.85)
            : btScanHover.pressed ? Theme.tint(Theme.surface0, 0.6)
            : btScanHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
            : Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.85)

        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text: Bluetooth.discovering ? "Scanning…" : "Scan for devices"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Bluetooth.discovering ? Theme.crust : Theme.text
        }

        MouseArea {
            id: btScanHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Bluetooth.toggleDiscovering()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Bluetooth.pairedDevices.length > 0
        spacing: 6

        SectionLabel { label: "Paired" }

        Repeater {
            model: Bluetooth.pairedDevices
            BluetoothDeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Bluetooth.otherDevices.length > 0
        spacing: 6

        SectionLabel { label: "Available" }

        Repeater {
            model: Bluetooth.otherDevices
            BluetoothDeviceRow {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
            }
        }
    }
}
