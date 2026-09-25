import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
  id: root
  spacing: 4

  Repeater {
    model: SystemTray.items

    Item {
      id: trayItem
      required property SystemTrayItem modelData
      implicitWidth: 20
      implicitHeight: 20

      Image {
        id: trayIcon
        anchors.centerIn: parent
        source: trayItem.modelData.icon
        implicitWidth: 16
        implicitHeight: 16
        sourceSize: Qt.size(16, 16)
      }

      ToolTip {
        id: tooltip
        visible: hoverHandler.hovered
        text: trayItem.modelData.title
        delay: 500
      }

      HoverHandler {
        id: hoverHandler
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) {
            trayItem.modelData.activate()
          } else {
            trayItem.modelData.secondaryActivate()
          }
        }
      }
    }
  }
}
