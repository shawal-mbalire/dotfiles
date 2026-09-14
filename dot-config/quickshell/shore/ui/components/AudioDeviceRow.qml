import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// One audio port row: select as default, mute, and set volume. The label is the
// short port name (Speaker, HDMI 1, ...) since the parent card is shown by the
// group header.
Rectangle {
    id: root

    required property var node
    property bool selected: false
    signal activate()

    readonly property var audio: root.node.audio

    implicitHeight: content.implicitHeight + 12
    radius: Theme.radius
    color: selected ? Theme.tint(WallpaperColors.accent, 0.75) : Theme.tint(Theme.surface0, 0.4)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.5)

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: AudioGroups.portLabel(root.node)
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: root.selected ? Theme.crust : Theme.text

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate()
                }
            }

            Text {
                visible: root.audio !== null
                text: root.audio && root.audio.muted ? "\uF026" : "\uF028"
                font.family: Theme.iconFontFamily
                font.pixelSize: 14
                color: root.selected ? Theme.crust : Theme.subtext0

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMute(root.node)
                }
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

        Slider {
            Layout.fillWidth: true
            value: root.audio ? root.audio.volume : 0
            accent: root.selected ? Theme.crust : Theme.sapphire
            trackColor: root.selected
                ? Theme.tint(Theme.crust, 0.35)
                : Theme.tint(Theme.surface1, 0.8)
            onMoved: v => Audio.setVolume(root.node, v)
        }
    }
}
