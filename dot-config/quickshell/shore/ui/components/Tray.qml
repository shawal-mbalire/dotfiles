import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Rectangle {
    id: root

    readonly property var items: SystemTray.items.values

    visible: items.length > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.5)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.6)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items
            TrayItem {
                required property var modelData
                item: modelData
            }
        }
    }
}
