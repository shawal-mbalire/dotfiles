import "../../../infra/config"
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
  id: root

  property string title: ""
  property string icon: ""
  property color iconColor: Theme.text
  default property alias content: layout.data

  radius: Theme.radius
  color: Theme.surface0
  border.color: Theme.surface1
  border.width: 1
  implicitHeight: layout.implicitHeight + Theme.padding * 2

  ColumnLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: Theme.padding
    spacing: Theme.spacing

    RowLayout {
      visible: root.title !== "" || root.icon !== ""
      spacing: Theme.spacing

      Text {
        text: root.icon
        color: root.iconColor
        font { family: Theme.nerdFont; pixelSize: 14; weight: Theme.fontWeight }
        visible: root.icon !== ""
      }

      Text {
        text: root.title
        color: Theme.text
        font { family: Theme.font; pixelSize: 13; weight: 800 }
        visible: root.title !== ""
      }

      Item { Layout.fillWidth: true }
    }
  }
}
