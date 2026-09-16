import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../../domain"
import "../../domain"
import "../../adapters"

Rectangle {
    id: root

    readonly property var filteredItems: Tray.items.filter(item => {
        const id = (item.id || "").toLowerCase();
        const title = (item.title || "").toLowerCase();
        // Exclude bluetooth and network — handled by the connectivity group.
        return id !== "blueman" && id !== "nm-applet"
            && title !== "bluetooth" && title !== "network";
    })

    visible: filteredItems.length > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.filteredItems
            TrayItem {
                required property var modelData
                item: modelData
            }
        }
    }
}
