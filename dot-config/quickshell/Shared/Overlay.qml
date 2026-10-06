import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
  id: root

  property string title: ""
  property string shellNamespace: "quickshell:overlay"

  // Emitted instead of writing `visible` directly, so the owner in shell.qml can
  // keep a single `visible:` binding per instance (one instance per screen).
  signal closeRequested()

  implicitWidth: 400
  implicitHeight: 400
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
  }

  margins.top: 60
  margins.left: Math.max(0, (screen.width - implicitWidth) / 2)
  margins.right: Math.max(0, (screen.width - implicitWidth) / 2)

  screen: Quickshell.screens[0]

  WlrLayershell.namespace: root.shellNamespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0
  visible: false

  Rectangle {
    anchors.fill: parent
    color: Theme.base
    radius: Theme.radiusLg
    border.color: Theme.surface1
    border.width: 1
  }
}
