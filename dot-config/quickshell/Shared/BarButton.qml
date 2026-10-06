import QtQuick
import QtQuick.Layouts
import "."

// Reusable bar affordance: a hover highlight, a pointing cursor, and an
// `activated()` intent. Wrap any bar widget in it to make the whole cluster
// hoverable and clickable. Uses handlers (not a MouseArea) so it stays a plain
// Item and never fights the parent layout.
Item {
  id: root

  default property alias content: inner.data
  signal activated()

  readonly property bool hovered: hover.hovered

  implicitWidth: inner.implicitWidth + Theme.spacingSm * 2
  implicitHeight: inner.implicitHeight + Theme.spacingSm

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSm
    color: Theme.surface1
    opacity: hover.hovered ? 0.7 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  RowLayout {
    id: inner
    anchors.centerIn: parent
    spacing: 0
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    onTapped: root.activated()
  }
}
