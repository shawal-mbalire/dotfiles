// A hair-thin layer-shell strip along the top edge of one screen.
//
// Sliding the pointer to the very top reveals the auto-hidden bar. The rightmost
// `cornerReserve` px are left to Bar/HotCorner, so the two input regions never
// overlap. It is always mapped, so it works whether or not the bar is currently shown.
import "../../../infra/config"
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  // Set by the owning Variants delegate to this strip's screen.
  property var modelData
  screen: modelData

  // Leave the top-right hot corner to Bar/HotCorner.
  property int cornerReserve: Theme.hotCornerWidth
  property int stripHeight: Theme.edgeStripHeight

  signal hoverEntered()
  signal hoverExited()

  anchors {
    top: true
    left: true
    right: true
  }
  margins.right: root.cornerReserve

  implicitHeight: root.stripHeight
  color: "transparent"
  exclusiveZone: 0
  WlrLayershell.namespace: "quickshell:bar-reveal"
  // Top, not Overlay: the strip stays under fullscreen windows instead of blocking
  // their top edge. The bar is also on Top, so the reveal works wherever the bar does.
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Item {
    anchors.fill: parent

    HoverHandler {
      onHoveredChanged: hovered ? root.hoverEntered() : root.hoverExited()
    }
  }
}
