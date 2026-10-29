import "../../../infra/config"
import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
  id: root
  property string title: ""; property string shellNamespace: "quickshell:overlay"
  property bool dismissOnOutsideClick: true; property bool showBackground: true
  property bool open: true; property int openOrigin: Item.Top
  default property alias content: body.data
  signal closeRequested(); signal closeFinished()

  implicitWidth: 400; implicitHeight: 400; color: "transparent"
  anchors { top: true; left: true; right: true }
  margins.top: Theme.barHeight
  margins.left: Math.max(0, (screen.width - implicitWidth) / 2)
  margins.right: Math.max(0, (screen.width - implicitWidth) / 2)
  screen: Quickshell.screens[0]

  WlrLayershell.namespace: root.shellNamespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0

  DismissGrab { window: root; enabled: root.open && root.dismissOnOutsideClick; onDismissed: root.closeRequested() }

  Item {
    id: body; anchors.fill: parent; enabled: root.open; opacity: 0; scale: 0.94; transformOrigin: root.openOrigin
    transform: Translate { id: slide; y: -10 }
    Rectangle { anchors.fill: parent; visible: root.showBackground; color: Theme.glass(Theme.base); radius: Theme.radiusLg; border.color: Theme.surface1; border.width: 1 }
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
    onFinished: root.closeFinished()
  }

  function playOpen() { exitAnim.stop(); enterAnim.restart() }
  onOpenChanged: { if (open) playOpen(); else { enterAnim.stop(); exitAnim.restart() } }
  Component.onCompleted: if (open) playOpen()
}
