import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// One audio device row: select as default, mute, and set volume.
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
                text: root.node.description || root.node.name
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
                    onClicked: if (root.audio) root.audio.muted = !root.audio.muted
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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: root.selected ? Theme.tint(Theme.crust, 0.35) : Theme.tint(Theme.surface1, 0.8)

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * Math.max(0, Math.min(1, root.audio ? root.audio.volume : 0))
                radius: parent.radius
                color: root.selected ? Theme.crust : Theme.sapphire
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function apply(x) {
                    if (root.audio) root.audio.volume = Math.max(0, Math.min(1, x / width));
                }
                onClicked: mouse => apply(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) apply(mouse.x);
                }
            }
        }
    }
}
