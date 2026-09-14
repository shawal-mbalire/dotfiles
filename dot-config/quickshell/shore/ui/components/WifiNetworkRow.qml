import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Rectangle {
    id: root

    required property var network

    signal requestPassword(var net)

    readonly property bool connected: network.connected
    readonly property bool secured: !Formatters.isOpenNetwork(
        network.security, Constants.securityOpen, Constants.securityUnknown)

    implicitHeight: 34
    radius: Theme.radius
    color: connected ? Theme.tint(WallpaperColors.accent, 0.75) : Theme.tint(Theme.surface0, 0.4)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.5)

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: root.network.name
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.connected ? Theme.crust : Theme.text
        }

        Text {
            visible: root.secured
            text: "\uF023"
            font.family: Theme.iconFontFamily
            font.pixelSize: 12
            color: root.connected ? Theme.crust : Theme.subtext0
        }

        Text {
            text: root.connected ? "connected" : Formatters.percent(root.network.signalStrength) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: root.connected ? Theme.crust : Theme.subtext0
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.network.known) root.network.forget();
                return;
            }
            if (root.connected) root.network.disconnect();
            else if (root.network.known || !root.secured) root.network.connect();
            else root.requestPassword(root.network);
        }
    }
}
