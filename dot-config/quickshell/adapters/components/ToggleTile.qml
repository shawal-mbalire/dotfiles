import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property color accent: WallpaperColors.accent

    signal toggled()

    implicitHeight: 58
    radius: Theme.radius
    color: active ? Theme.tint(accent, 0.8)
         : tileHover.pressed ? Theme.tint(Theme.surface0, 0.6)
         : tileHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
         : Theme.tint(Theme.surface0, 0.5)
    border.width: 1
    border.color: active ? Theme.tint(accent, 0.9) : Theme.tint(Theme.surface1, 0.85)

    Behavior on color { ColorAnimation { duration: 80 } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: root.active ? Theme.crust : Theme.subtext1
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: root.active ? Theme.crust : Theme.subtext0
        }
    }

    MouseArea {
        id: tileHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
