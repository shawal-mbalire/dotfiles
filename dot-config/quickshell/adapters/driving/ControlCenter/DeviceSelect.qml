import "../../../infra/config"
import QtQuick
import QtQuick.Layouts

// One audio device section: a header that names its kind (OUTPUT or INPUT) and the
// current device, and every eligible device as a row. Choosing a row emits chosen().
// The volume card decides when the section is visible.
ColumnLayout {
  id: root

  property string kind: ""
  property string icon: ""
  // [{ name, label }]
  property var items: []
  property string currentName: ""

  readonly property string currentLabel: {
    const match = items.find(s => s.name === currentName)
    return match ? match.label : (currentName !== "" ? currentName : "None")
  }

  signal chosen(string name)

  Layout.fillWidth: true
  spacing: Theme.spacingSm

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.spacingSm

    Text {
      text: root.icon
      color: Theme.overlay1
      font { family: Theme.nerdFont; pixelSize: 13 }
    }

    Text {
      text: root.kind
      color: Theme.overlay1
      font { family: Theme.font; pixelSize: 9; weight: 800 }
    }

    Text {
      Layout.fillWidth: true
      text: root.currentLabel
      textFormat: Text.PlainText
      color: Theme.subtext0
      font { family: Theme.font; pixelSize: 10; weight: 600 }
      elide: Text.ElideRight
    }
  }

  Column {
    id: list
    Layout.fillWidth: true
    spacing: 2

    Repeater {
      model: root.items

      delegate: Rectangle {
        id: row
        required property var modelData
        readonly property bool current: modelData.name === root.currentName

        width: list.width
        height: 28
        radius: Theme.radiusSm
        color: current ? Theme.surface2 : (area.containsMouse ? Theme.surface1 : "transparent")

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: Theme.padding
          anchors.rightMargin: Theme.padding
          text: row.modelData.label
          textFormat: Text.PlainText
          color: row.current ? Theme.text : Theme.subtext0
          font { family: Theme.font; pixelSize: 11; weight: row.current ? 800 : 600 }
          elide: Text.ElideRight
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.chosen(row.modelData.name)
        }
      }
    }
  }
}
