import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Wi-Fi management: power, scan, pick a network, enter a password inline.
ColumnLayout {
    id: root

    readonly property var device: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi) return devices[i];
        return null;
    }

    readonly property var networks: {
        if (!device) return [];
        return Formatters.sortWifiNetworks(device.networks.values);
    }

    property var passwordTarget: null

    implicitWidth: 296
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MenuTitle {
            title: "Wi-Fi"
            subtitle: !root.device ? "No device"
                : Networking.wifiEnabled ? (root.device.name || "On")
                : "Off"
        }

        ToggleSwitch {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.device
        text: "No Wi-Fi device"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        visible: root.device && Networking.wifiEnabled
        radius: Theme.radius
        color: root.device && root.device.scannerEnabled
            ? Theme.tint(Theme.blue, 0.8)
            : Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.5)

        Text {
            anchors.centerIn: parent
            text: root.device && root.device.scannerEnabled ? "Scanning…" : "Scan for networks"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.device && root.device.scannerEnabled ? Theme.crust : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.device) root.device.scannerEnabled = !root.device.scannerEnabled
        }
    }

    // Inline password prompt for a secured, unknown network.
    Rectangle {
        Layout.fillWidth: true
        visible: root.passwordTarget !== null
        implicitHeight: prompt.implicitHeight + 16
        radius: Theme.radius
        color: Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.mauve, 0.5)

        ColumnLayout {
            id: prompt
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Password for " + (root.passwordTarget ? root.passwordTarget.name : "")
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.subtext0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Theme.radius - 3
                    color: Theme.tint(Theme.surface1, 0.5)
                    border.width: 1
                    border.color: Theme.tint(Theme.surface1, 0.6)

                    TextInput {
                        id: passwordInput
                        anchors {
                            fill: parent
                            leftMargin: 6
                            rightMargin: 6
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        clip: true
                        selectByMouse: true
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        onAccepted: root.submitPassword()
                    }
                }

                MenuButton {
                    label: "Connect"
                    onClicked: root.submitPassword()
                }
            }
        }

        onVisibleChanged: if (visible) passwordInput.forceActiveFocus()
    }

    Text {
        Layout.fillWidth: true
        visible: root.device && Networking.wifiEnabled && root.networks.length === 0
        text: "No networks — scan to find some"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }

    SectionLabel {
        Layout.topMargin: 2
        label: "Networks"
    }

    ListView {
        Layout.fillWidth: true
        visible: root.networks.length > 0
        implicitHeight: Math.min(contentHeight, 300)
        model: root.networks
        spacing: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: WifiNetworkRow {
            required property var modelData
            width: ListView.view.width
            network: modelData
            onRequestPassword: net => {
                root.passwordTarget = net;
                passwordInput.text = "";
            }
        }
    }

    function submitPassword() {
        if (!root.passwordTarget) return;
        root.passwordTarget.connectWithPsk(passwordInput.text);
        root.passwordTarget = null;
        passwordInput.text = "";
    }
}
