import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../../domain"
import "../../adapters"

// Volume / brightness OSD. Created only while visible so the window tree does
// not cost memory when idle.
LazyLoader {
    id: loader
    active: UiState.osdVisible

    PanelWindow {
        anchors.bottom: true
        margins.bottom: screen ? screen.height / 6 : 120
        exclusiveZone: 0
        implicitWidth: 320
        implicitHeight: 48
        color: "transparent"
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.85)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.85)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: UiState.osdIcon
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 18
                    color: Theme.text
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: Theme.radius
                    color: Theme.tint(Theme.surface0, 0.85)

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: parent.width * Math.max(0, Math.min(1, UiState.osdValue))
                        radius: parent.radius
                        color: WallpaperColors.accent
                    }
                }

                Text {
                    visible: UiState.osdLabel !== ""
                    text: UiState.osdLabel
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.subtext1
                }
            }
        }
    }
}
