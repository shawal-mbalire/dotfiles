import QtQuick
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Larger, hover-highlighted control button for the media player.
// Uses the inherited Item.enabled so a disabled button blocks its MouseArea.
Rectangle {
    id: root

    property string icon: ""
    property bool active: false

    signal triggered()

    implicitWidth: 38
    implicitHeight: 30
    radius: Theme.radius - 2
    opacity: enabled ? 1 : 0.4
    color: active ? Theme.tint(Theme.blue, 0.85)
         : hover.containsMouse ? Theme.tint(Theme.surface1, 0.6)
         : Theme.tint(Theme.surface0, 0.35)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.5)

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.iconFontFamily
        font.pixelSize: 16
        color: root.active ? Theme.crust : Theme.text
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
