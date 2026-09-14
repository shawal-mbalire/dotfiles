import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

ColumnLayout {
    id: root

    implicitWidth: 260
    spacing: 6

    MenuTitle {
        title: "Power profile"
        subtitle: PowerProfile.toString(PowerProfiles.profile)
    }

    Repeater {
        model: [
            { "label": "Power Saver", "value": PowerProfile.PowerSaver, "accent": Theme.blue },
            { "label": "Balanced", "value": PowerProfile.Balanced, "accent": Theme.green },
            { "label": "Performance", "value": PowerProfile.Performance, "accent": Theme.red }
        ]

        Rectangle {
            id: row
            required property var modelData
            readonly property bool current: PowerProfiles.profile === row.modelData.value

            Layout.fillWidth: true
            implicitHeight: 32
            radius: Theme.radius
            color: current ? Theme.tint(row.modelData.accent, 0.8) : Theme.tint(Theme.surface0, 0.4)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.5)

            Text {
                anchors.centerIn: parent
                text: row.modelData.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: row.current ? Theme.crust : Theme.text
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfiles.profile = row.modelData.value
            }
        }
    }
}
