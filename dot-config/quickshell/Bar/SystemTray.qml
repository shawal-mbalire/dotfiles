import "../Shared"
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
        width: 16
        height: 16
        sourceSize: Qt.size(16, 16)
        fillMode: Image.PreserveAspectFit
      }

      HoverHandler { id: hoverHandler }

      QsMenuAnchor {
        id: trayMenu
        menu: trayItem.modelData.menu
        anchor.item: trayItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
      }

      Rectangle {
        id: tooltip
        visible: hoverHandler.hovered && tipLabel.text !== ""
        y: trayItem.height + 6
        x: Math.min(Math.max(0, -trayItem.x + 8), parent.parent.width - width - 8)
        implicitWidth: tipLabel.implicitWidth + 16
        implicitHeight: tipLabel.implicitHeight + 10
        radius: Theme.radiusSm
        color: Theme.surface2
        z: 10

        Text {
          id: tipLabel
          anchors.centerIn: parent
          text: trayItem.modelData.title
          color: Theme.text
          font { family: Theme.font; pixelSize: 11; weight: 700 }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(mouse) {
          const item = trayItem.modelData
          if (mouse.button === Qt.LeftButton) {
            if (item.onlyMenu && item.hasMenu) trayMenu.open()
            else item.activate()
          } else if (item.hasMenu) {
            trayMenu.open()
          } else {
            item.secondaryActivate()
          }
        }
      }
    }
  }
}
