import QtQuick
import QtQuick.Layouts
import "."

// Compact controlled slider. `value` is the single source of truth: interaction
// only emits `changed()`, and the handle position is always derived from
// `value`, so an external `value:` binding is never destroyed. The optional
// icon/label row is hidden when neither is supplied, keeping the widget short.
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
  // Eases toward `ratio` for external changes (media keys), but tracks the
  // pointer exactly while dragging.
  property real shownRatio: ratio
  Behavior on shownRatio {
    enabled: !trackArea.pressed
    NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut }
  }

  // The track thickens and the handle grows while hovered or dragged.
  readonly property bool trackActive: trackArea.pressed || trackArea.containsMouse
  readonly property int trackThickness: trackActive ? 6 : 4

  spacing: Theme.spacingSm

  function applyMouse(mouse) {
    const r = Math.max(0, Math.min(1, mouse.x / track.width))
    const val = Math.round(minValue + r * span)
    if (val !== value) changed(val)
  }

  RowLayout {
    Layout.fillWidth: true
    visible: root.icon !== "" || root.label !== ""
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
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.spacingSm

    Item {
      id: track
      Layout.fillWidth: true
      implicitHeight: 16

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackThickness
        radius: height / 2
        color: root.bgColor

        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * root.shownRatio
        height: root.trackThickness
        radius: height / 2
        color: root.barColor

        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
      }

      Rectangle {
        id: handle
        x: track.width * root.shownRatio - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: root.trackActive ? root.barColor : root.handleColor
        border.color: root.barColor
        border.width: 2
        scale: root.trackActive ? 1.15 : 1.0

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeEmphasized } }
      }

      MouseArea {
        id: trackArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => root.applyMouse(mouse)
        onPositionChanged: mouse => { if (pressed) root.applyMouse(mouse) }
      }
    }

    Text {
      text: root.value + "%"
      color: Theme.overlay0
      font { family: Theme.font; pixelSize: 12; weight: 600 }
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
