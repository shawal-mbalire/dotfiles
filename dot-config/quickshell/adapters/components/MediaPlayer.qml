import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

Rectangle {
    id: root

    readonly property var player: Media.current

    visible: player !== null
    implicitHeight: visible ? content.implicitHeight + 16 : 0
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 6

        // ── Artwork + track info ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                implicitWidth: 48
                implicitHeight: 48
                radius: Theme.radius - 3
                color: Theme.tint(Theme.surface1, 0.85)
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: Theme.text
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext0
                }
            }
        }

        // ── Controls row ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            MediaButton {
                icon: "\uF048"
                enabled: root.player && root.player.canGoPrevious
                onTriggered: Media.previous()
            }

            MediaButton {
                icon: root.player && root.player.isPlaying ? "\uF04C" : "\uF04B"
                active: true
                enabled: root.player && root.player.canTogglePlaying
                onTriggered: Media.togglePlaying()
            }

            MediaButton {
                icon: "\uF051"
                enabled: root.player && root.player.canGoNext
                onTriggered: Media.next()
            }

            Item { Layout.fillWidth: true }
        }
    }
}
