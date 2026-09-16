import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"

// Minimal bar icon that opens a grouped menu.
Rectangle {
    id: root

    required property string group
    required property string icon

    property color iconColor: Theme.subtext1

    implicitWidth: layout.implicitWidth + Theme.padH * 2
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            color: root.iconColor
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleMenu(root.group)
    }
}
