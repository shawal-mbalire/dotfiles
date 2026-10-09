import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."

// Passive on-screen display for volume / brightness changes. Sits top-centre
// under the bar, is click-through (empty input mask) and takes no focus; the
// owner drives `active`, `kind` and `level`.
PanelWindow {
  id: root

  property string kind: "volume" // "volume" | "brightness"
  property int level: 0
  property bool active: false

  readonly property bool isBrightness: kind === "brightness"
  readonly property string icon: {
    if (isBrightness) {
      if (level <= 0) return String.fromCodePoint(0xF00DA)
      if (level < 34) return String.fromCodePoint(0xF00DC)
      if (level < 67) return String.fromCodePoint(0xF00DE)
      return String.fromCodePoint(0xF00E0)
    }
    if (level <= 0) return String.fromCodePoint(0xF0581)
    if (level < 34) return String.fromCodePoint(0xF057F)
    if (level < 67) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }
  readonly property color accent: isBrightness ? Theme.peach : Theme.yellow

  color: "transparent"
  implicitWidth: 260
  implicitHeight: 46

  anchors {
    top: true
    left: true
    right: true
  }
  margins.top: Theme.barHeight + 10
  margins.left: Math.max(0, (screen.width - implicitWidth) / 2)
  margins.right: Math.max(0, (screen.width - implicitWidth) / 2)

  exclusiveZone: 0
  WlrLayershell.namespace: "quickshell:osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  // Empty input region: the OSD never intercepts clicks.
  mask: Region {}

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: Theme.base
    border.color: Theme.surface1
    border.width: 1
    opacity: root.active ? 1 : 0
    scale: root.active ? 1 : 0.9

    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeEmphasized } }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Theme.paddingLg
      anchors.rightMargin: Theme.paddingLg
      spacing: Theme.spacing

      Text {
        text: root.icon
        color: root.accent
        font { family: Theme.nerdFont; pixelSize: 18; weight: Theme.fontWeight }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.surface1

        Rectangle {
          width: parent.width * Math.max(0, Math.min(100, root.level)) / 100
          height: parent.height
          radius: 3
          color: root.accent

          Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeOut } }
        }
      }

      Text {
        text: root.level + "%"
        color: Theme.text
        font { family: Theme.font; pixelSize: 13; weight: 800 }
      }
    }
  }
}
