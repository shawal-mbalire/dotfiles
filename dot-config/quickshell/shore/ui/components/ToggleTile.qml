import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property color accent: Theme.blue

    signal toggled()

    implicitHeight: 58
    radius: Theme.radius
    color: active ? Theme.tint(accent, 0.8) : Theme.tint(Theme.surface0, 0.5)
    border.width: 1
    border.color: active ? Theme.tint(accent, 0.9) : Theme.tint(Theme.surface1, 0.5)

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
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
