import "../../../infra/config"
import Quickshell
import Quickshell.Wayland
import QtQuick

Item {
  id: root
  property var modelData
  signal hoverEntered()
  signal hoverExited()
  signal triggered()

  // ── Top-edge reveal strip ───────────────────────────────────────────────
  PanelWindow {
    id: stripWindow
    screen: root.modelData
    anchors { top: true; left: true; right: true }
    margins.right: Theme.hotCornerWidth
    implicitHeight: Theme.edgeStripHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell:bar-reveal"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
      anchors.fill: parent
      HoverHandler { onHoveredChanged: hovered ? root.hoverEntered() : root.hoverExited() }
    }
  }

  // ── Top-right hot corner ────────────────────────────────────────────────
  PanelWindow {
    id: cornerWindow
    screen: root.modelData
    anchors { top: true; right: true }
    implicitWidth: Theme.hotCornerWidth
    implicitHeight: Theme.edgeStripHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell:hot-corner"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer { id: dwell; interval: 180; onTriggered: if (cornerHover.hovered) root.triggered() }

    Item {
      anchors.fill: parent
      HoverHandler {
        id: cornerHover
        onHoveredChanged: {
          if (hovered) { root.hoverEntered(); dwell.restart() }
          else { dwell.stop(); root.hoverExited() }
        }
      }
    }
  }
}
