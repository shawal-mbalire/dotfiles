import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// Transient notification toast, top-right under the bar.
LazyLoader {
    id: loader
    active: Notifications.popupVisible && Notifications.lastNotification !== null

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.barHeight + 4
            right: 8
        }
        implicitWidth: 340
        implicitHeight: card.implicitHeight
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: layout.implicitHeight + 20
            radius: Theme.radius
            color: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.85)
            border.width: 1
            border.color: Theme.tint(Theme.mauve, 0.4)

            ColumnLayout {
                id: layout
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: Notifications.lastNotification ? Notifications.lastNotification.appName : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.mauve
                }

                Text {
                    Layout.fillWidth: true
                    text: Notifications.lastNotification ? Notifications.lastNotification.summary : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: Theme.text
                }

                Text {
                    Layout.fillWidth: true
                    visible: Notifications.lastNotification && Notifications.lastNotification.body !== ""
                    text: Notifications.lastNotification ? Notifications.lastNotification.body : ""
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext0
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Notifications.closePopup()
            }
        }
    }
}
