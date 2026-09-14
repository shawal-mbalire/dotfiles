import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property SystemTrayItem item

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
            if (mouse.button === Qt.LeftButton) root.item.activate();
            else if (mouse.button === Qt.MiddleButton) root.item.secondaryActivate();
            else if (root.item.hasMenu) root.item.display(root, mouse.x, mouse.y);
        }
        onWheel: wheel => root.item.scroll(wheel.angleDelta.y, wheel.angleDelta.x !== 0)
    }
}
