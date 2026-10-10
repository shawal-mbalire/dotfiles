import "../../../infra/config"
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
  id: root

  property bool checked: false
  property string label: ""
  property string icon: ""
  property color checkedColor: Theme.blue
  property color uncheckedColor: Theme.surface1
  signal toggled(bool checked)

  implicitWidth: row.implicitWidth + Theme.padding * 2
  implicitHeight: 28
  radius: height / 2
  color: checked ? checkedColor : uncheckedColor

  Behavior on color { ColorAnimation { duration: 150 } }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: Theme.spacingSm

    Text {
      text: root.icon
      color: root.checked ? Theme.crust : Theme.subtext0
      font { family: Theme.nerdFont; pixelSize: 12; weight: Theme.fontWeight }
      visible: root.icon !== ""
    }

    Text {
      text: root.label
      color: root.checked ? Theme.crust : Theme.subtext0
      font { family: Theme.font; pixelSize: 11; weight: 700 }
      visible: root.label !== ""
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled(!root.checked)
  }
}
