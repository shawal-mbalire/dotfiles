import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../domain"
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
    color: connected ? Theme.tint(WallpaperColors.accent, 0.85)
         : wifiRowHover.pressed ? Theme.tint(Theme.surface0, 0.6)
         : wifiRowHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
         : Theme.tint(Theme.surface0, 0.5)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    Behavior on color { ColorAnimation { duration: 80 } }

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
        id: wifiRowHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.network.known) Network.forgetNetwork(root.network);
                return;
            }
            if (root.connected) Network.disconnectNetwork(root.network);
            else if (root.network.known || !root.secured) Network.connectNetwork(root.network);
            else root.requestPassword(root.network);
        }
    }
}
