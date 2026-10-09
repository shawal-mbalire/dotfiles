import QtQuick
import QtQuick.Layouts
import "."

// A compact card with a clickable header. Its body collapses to zero height and
// expands with an animation when the owner sets `expanded`. Declared children
// land in the collapsible body (the default property aliases it), so a card is
// written as `CollapsibleCard { ...options... }`.
Rectangle {
  id: root

  property string title: ""
  property string icon: ""
  property color iconColor: Theme.text
  property string summary: ""
  property bool expanded: false
  signal toggleRequested()

  default property alias content: bodyContent.data

  implicitWidth: 160
  implicitHeight: column.implicitHeight + Theme.padding * 2
  radius: Theme.radius
  color: headerHover.hovered ? Theme.surface1 : Theme.surface0
  border.color: root.expanded ? Theme.surface2 : Theme.surface1
  border.width: 1

  Behavior on color { ColorAnimation { duration: Theme.animFast } }
  Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: Theme.padding
    spacing: Theme.spacing

    RowLayout {
      id: header
      Layout.fillWidth: true
      spacing: Theme.spacingSm

      // Handlers sit alongside the visual children; layouts ignore non-Items.
      TapHandler { onTapped: root.toggleRequested() }
      HoverHandler { id: headerHover; cursorShape: Qt.PointingHandCursor }

      Text {
        text: root.icon
        color: root.iconColor
        font { family: Theme.nerdFont; pixelSize: 14; weight: Theme.fontWeight }
      }

      Text {
        text: root.title
        color: Theme.text
        font { family: Theme.font; pixelSize: 12; weight: 800 }
        elide: Text.ElideRight
      }

      Item { Layout.fillWidth: true }

      Text {
        text: root.summary
        color: Theme.overlay0
        font { family: Theme.font; pixelSize: 10; weight: 600 }
        elide: Text.ElideRight
      }

      Text {
        text: String.fromCodePoint(0xF0140) // md-chevron_down
        color: Theme.overlay0
        font { family: Theme.nerdFont; pixelSize: 14 }
        rotation: root.expanded ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
      }
    }

    Item {
      id: body
      Layout.fillWidth: true
      implicitHeight: root.expanded ? bodyContent.implicitHeight : 0
      clip: true
      opacity: root.expanded ? 1 : 0

      Behavior on implicitHeight { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
      Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

      ColumnLayout {
        id: bodyContent
        width: parent.width
        spacing: Theme.spacing
      }
    }
  }
}
