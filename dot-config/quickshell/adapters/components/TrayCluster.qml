import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../../domain"
import "../../adapters"

Rectangle {
    id: root

    property var _filteredItems: []

    function _recomputeFiltered() {
        const items = Tray.items;
        const result = [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const id = (item.id || "").toLowerCase();
            const title = (item.title || "").toLowerCase();
            if (id !== "blueman" && id !== "nm-applet"
                && title !== "bluetooth" && title !== "network")
                result.push(item);
        }
        root._filteredItems = result;
    }

    Timer {
        id: refilterDebounce
        interval: 100
        onTriggered: root._recomputeFiltered()
    }

    Connections {
        target: Tray
        function onItemsChanged() { refilterDebounce.restart(); }
    }

    Component.onCompleted: _recomputeFiltered()

    readonly property var filteredItems: root._filteredItems

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
