import QtQuick
import Quickshell.Widgets
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Item {
    id: root

    required property var item

    implicitWidth: 18
    implicitHeight: 18

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: 18
        // SystemTrayItem.icon is already an image://icon/... URL (or a file path).
        source: {
            const value = root.item.icon;
            if (!value) return "";
            if (value.startsWith("image://")) return value;
            if (value.startsWith("/")) return "file://" + value;
            return "image://icon/" + value;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) Tray.activate(root.item);
            else if (mouse.button === Qt.MiddleButton) Tray.secondaryActivate(root.item);
            else Tray.display(root.item, root, mouse.x, mouse.y);
        }
        onWheel: wheel => Tray.scroll(root.item, wheel.angleDelta.y, wheel.angleDelta.x !== 0)
    }
}
