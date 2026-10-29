import "../../../infra/config"
import "../Shared"
import "../../../domain/constants"
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
      readonly property bool suppressed: TrayPolicy.isSuppressed(modelData.id, modelData.title)
      visible: !suppressed; implicitWidth: suppressed ? 0 : 20; implicitHeight: suppressed ? 0 : 20

      Image { anchors.centerIn: parent; source: trayItem.modelData.icon; width: 16; height: 16; sourceSize: Qt.size(16, 16); fillMode: Image.PreserveAspectFit }
      HoverHandler { id: hoverHandler }
      QsMenuAnchor { id: trayMenu; menu: trayItem.modelData.menu; anchor { item: trayItem; edges: Edges.Bottom; gravity: Edges.Bottom } }

      PopupWindow {
        id: tooltip; anchor { item: trayItem; edges: Edges.Bottom; gravity: Edges.Bottom }
        visible: hoverHandler.hovered && tipLabel.text !== ""; implicitWidth: tipLabel.implicitWidth + 16; implicitHeight: tipLabel.implicitHeight + 10; color: "transparent"
        Rectangle {
          anchors.fill: parent; radius: Theme.radiusSm; color: Theme.surface2
          Text { id: tipLabel; anchors.centerIn: parent; text: trayItem.modelData.title; color: Theme.text; font { family: Theme.font; pixelSize: 11; weight: 700 } }
        }
      }

      MouseArea {
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => {
          const item = trayItem.modelData
          if (m.button === Qt.LeftButton) (item.onlyMenu && item.hasMenu) ? trayMenu.open() : item.activate()
          else if (item.hasMenu) trayMenu.open()
          else item.secondaryActivate()
        }
      }
    }
  }
}
