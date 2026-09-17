import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

Rectangle {
    id: root

    required property var notification

    implicitHeight: layout.implicitHeight + 16
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    ColumnLayout {
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.notification.appName
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: WallpaperColors.accent
            }

            Text {
                text: "\uF00D"
                font.family: Theme.iconFontFamily
                font.pixelSize: 11
                color: Theme.overlay0

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notification.dismiss()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.notification.summary
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.text
        }

        Text {
            Layout.fillWidth: true
            visible: root.notification.body !== ""
            text: root.notification.body
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.subtext0
        }
    }
}
