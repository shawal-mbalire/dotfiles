import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

// One audio device row: select as default with a single click. Shows device
// name, type icon, and mute toggle. No per-device volume slider -- the master
// volume controls the default device.
Rectangle {
    id: root

    required property var node
    property bool selected: false
    signal activate()

    readonly property var audio: root.node.audio

    implicitHeight: Theme.menuRowHeight
    radius: Theme.radius
    color: selected ? Theme.tint(WallpaperColors.accent, 0.85)
         : rowHover.pressed ? Theme.tint(Theme.surface0, 0.6)
         : rowHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
         : Theme.tint(Theme.surface0, 0.5)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    Behavior on color { ColorAnimation { duration: 80 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            text: AudioGroups.portLabel(root.node)
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.selected ? Theme.crust : Theme.text
        }

        Item { Layout.fillWidth: true }

        Text {
            visible: root.audio !== null
            text: root.audio && root.audio.muted ? Theme.iconVolumeMuted : Theme.iconVolume
            font.family: Theme.iconFontFamily
            font.pixelSize: 14
            color: root.selected ? Theme.crust : Theme.subtext0
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: root.audio ? Formatters.percent(root.audio.volume) + "%" : "--"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: root.selected ? Theme.crust : Theme.subtext0
        }
    }

    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}
