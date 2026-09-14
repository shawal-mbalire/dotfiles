import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Rectangle {
    id: root

    property string icon: ""
    property real value: 0
    property string label: ""
    property color accent: WallpaperColors.accent

    signal moved(real value)

    implicitHeight: 34
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.4)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.5)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            text: root.icon
            font.family: Theme.iconFontFamily
            font.pixelSize: 15
            color: Theme.subtext1
        }

        Slider {
            Layout.fillWidth: true
            value: root.value
            accent: root.accent
            onMoved: v => root.moved(v)
        }

        Text {
            Layout.preferredWidth: 30
            text: root.label
            horizontalAlignment: Text.AlignRight
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.subtext0
        }
    }
}
