import QtQuick
import QtQuick.Layouts
import "."

ColumnLayout {
  id: root

  property string label: ""
  property string icon: ""
  property color iconColor: Theme.text
  property int value: 50
  property int minValue: 0
  property int maxValue: 100
  property color barColor: Theme.blue
  property color bgColor: Theme.surface0
  property color handleColor: Theme.text
  signal changed(int value)

  readonly property real span: Math.max(1, maxValue - minValue)
  readonly property real ratio: Math.max(0, Math.min(1, (value - minValue) / span))

  spacing: Theme.spacingSm

  // Controlled component: `value` is the single source of truth. Interaction only
  // emits `changed()`; the handle position is always derived from `value`, so the
  // parent's `value:` binding is never destroyed and external updates keep working.
  function applyMouse(mouse) {
    const r = Math.max(0, Math.min(1, mouse.x / track.width))
    const val = Math.round(minValue + r * span)
    if (val !== value) changed(val)
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.spacing

    Text {
      text: root.icon
      color: root.iconColor
      font { family: Theme.nerdFont; pixelSize: 14; weight: Theme.fontWeight }
      visible: root.icon !== ""
    }

    Text {
      text: root.label
      color: Theme.text
      font { family: Theme.font; pixelSize: 13; weight: 800 }
      visible: root.label !== ""
    }

    Item { Layout.fillWidth: true }

    Text {
      text: root.value + "%"
      color: Theme.overlay0
      font { family: Theme.font; pixelSize: 12; weight: 600 }
    }
  }

  Item {
    id: track
    Layout.fillWidth: true
    implicitHeight: 20

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: 3
      color: root.bgColor
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * root.ratio
      height: 6
      radius: 3
      color: root.barColor
    }

    Rectangle {
      id: handle
      x: track.width * root.ratio - width / 2
      anchors.verticalCenter: parent.verticalCenter
      width: 16
      height: 16
      radius: 8
      color: trackArea.pressed ? root.barColor : root.handleColor
      border.color: root.barColor
      border.width: 2

      Behavior on color { ColorAnimation { duration: 100 } }
      Behavior on scale { NumberAnimation { duration: 100 } }
    }

    MouseArea {
      id: trackArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onPressed: function(mouse) {
        handle.scale = 1.2
        root.applyMouse(mouse)
      }
      onPositionChanged: function(mouse) {
        if (pressed) root.applyMouse(mouse)
      }
      onReleased: handle.scale = 1.0
      onCanceled: handle.scale = 1.0
    }
  }
}
