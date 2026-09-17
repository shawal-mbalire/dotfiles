import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

BaseMenu {
    id: root

    MenuTitle {
        title: "Power profile"
        subtitle: Battery.profileLabel
    }

    Repeater {
        model: Battery.profiles

        Rectangle {
            id: row
            required property var modelData
            readonly property bool current: Battery.profile === row.modelData.value
            readonly property color accent: row.modelData.label === "Performance" ? Theme.red
                : row.modelData.label === "Power Saver" ? Theme.blue
                : Theme.green

            Layout.fillWidth: true
            implicitHeight: Theme.menuRowHeight
            radius: Theme.radius
            color: current ? Theme.tint(row.accent, 0.8)
                 : rowHover.pressed ? Theme.tint(Theme.surface0, 0.6)
                 : rowHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
                 : Theme.tint(Theme.surface0, 0.5)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.85)

            Behavior on color { ColorAnimation { duration: 80 } }

            Text {
                anchors.centerIn: parent
                text: row.modelData.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: row.current ? Theme.crust : Theme.text
            }

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Battery.setProfile(row.modelData.value)
            }
        }
    }
}
