import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

// Workspace buttons. Each workspace carries its own bindable data, so a plain
// Repeater over the model rebinds on state changes without a timer.
Rectangle {
    id: root

    implicitWidth: row.implicitWidth + 6
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: Compositor.workspaces

            Rectangle {
                id: ws
                required property var modelData

                implicitWidth: Math.max(22, label.implicitWidth + 12)
                implicitHeight: Theme.barHeight - 12
                radius: Theme.radius - 3
                color: modelData.urgent ? Theme.red
                     : modelData.focused ? WallpaperColors.accent
                     : modelData.active ? Theme.tint(Theme.overlay0, 0.45)
                     : "transparent"

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: ws.modelData.name
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: (ws.modelData.focused || ws.modelData.urgent) ? Theme.crust : Theme.subtext1
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Compositor.activateWorkspace(ws.modelData)
                }
            }
        }
    }
}
