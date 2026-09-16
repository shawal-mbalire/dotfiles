import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// Wi-Fi management: power, scan, pick a network, enter a password inline.
// All NetworkManager access goes through the Network adapter.
ColumnLayout {
    id: root

    readonly property var device: Network.wifiDevice
    readonly property var networks: Network.wifiNetworks

    property var passwordTarget: null

    implicitWidth: 296
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MenuTitle {
            title: "Wi-Fi"
            subtitle: !root.device ? "No device"
                : Network.wifiEnabled ? (root.device.name || "On")
                : "Off"
        }

        ToggleSwitch {
            checked: Network.wifiEnabled
            onToggled: Network.toggleWifi()
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
        visible: root.device && Network.wifiEnabled
        radius: Theme.radius
        color: Network.wifiScanning
            ? Theme.tint(WallpaperColors.accent, 0.85)
            : Theme.tint(Theme.surface0, 0.85)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.85)

        Text {
            anchors.centerIn: parent
            text: Network.wifiScanning ? "Scanning…" : "Scan for networks"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Network.wifiScanning ? Theme.crust : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Network.toggleScanner()
        }
    }

    // Inline password prompt for a secured, unknown network.
    Rectangle {
        Layout.fillWidth: true
        visible: root.passwordTarget !== null
        implicitHeight: prompt.implicitHeight + 16
        radius: Theme.radius
        color: Theme.tint(Theme.surface0, 0.85)
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
                    color: Theme.tint(Theme.surface1, 0.85)
                    border.width: 1
                    border.color: Theme.tint(Theme.surface1, 0.85)

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
        visible: root.device && Network.wifiEnabled && root.networks.length === 0
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
        Network.connectWithPsk(root.passwordTarget, passwordInput.text);
        root.passwordTarget = null;
        passwordInput.text = "";
    }
}
