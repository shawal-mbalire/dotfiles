import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
  id: root

  property string title: ""
  property string shellNamespace: "quickshell:overlay"
  // Clicking anywhere outside the overlay emits closeRequested().
  property bool dismissOnOutsideClick: true
  // Draw the rounded backdrop; off for windows whose children are their own cards.
  property bool showBackground: true

  // false plays the exit animation, after which closed() is emitted and the
  // owner may destroy the window. true (re)plays the enter animation.
  property bool open: true
  // Corner the open/close scale grows from.
  property int openOrigin: Item.Top

  // Children of an Overlay land in the animated body, not the bare window.
  default property alias content: body.data

  // Emitted instead of writing `visible` directly; the owner in shell.qml
  // decides whether the overlay exists at all.
  signal closeRequested()
  signal closed()

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

  DismissGrab {
    window: root
    enabled: root.open && root.dismissOnOutsideClick
    onDismissed: root.closeRequested()
  }

  Item {
    id: body
    anchors.fill: parent
    enabled: root.open
    opacity: 0
    scale: 0.94
    transformOrigin: root.openOrigin
    transform: Translate { id: slide; y: -10 }

    Rectangle {
      anchors.fill: parent
      visible: root.showBackground
      color: Theme.base
      radius: Theme.radiusLg
      border.color: Theme.surface1
      border.width: 1
    }
  }

  ParallelAnimation {
    id: enterAnim
    NumberAnimation { target: body; property: "opacity"; to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
    NumberAnimation { target: body; property: "scale"; to: 1; duration: Theme.animSlow; easing.type: Theme.easeEmphasized }
    NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.animSlow; easing.type: Theme.easeOut }
  }

  ParallelAnimation {
    id: exitAnim
    NumberAnimation { target: body; property: "opacity"; to: 0; duration: Theme.animFast; easing.type: Theme.easeIn }
    NumberAnimation { target: body; property: "scale"; to: 0.96; duration: Theme.animFast; easing.type: Theme.easeIn }
    NumberAnimation { target: slide; property: "y"; to: -6; duration: Theme.animFast; easing.type: Theme.easeIn }
    onFinished: root.closed()
  }

  function playOpen() {
    exitAnim.stop()
    enterAnim.restart()
  }

  onOpenChanged: {
    if (open) {
      playOpen()
    } else {
      enterAnim.stop()
      exitAnim.restart()
    }
  }

  Component.onCompleted: if (open) playOpen()
}
