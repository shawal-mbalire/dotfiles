// A hair-thin layer-shell strip along the top edge of one screen.
//
// Sliding the pointer to the very top reveals the auto-hidden bar. The rightmost
// `cornerReserve` px are left to Bar/HotCorner, so the two input regions never
// overlap. It lives on the Overlay layer so it works whether or not the bar is
// currently mapped.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  // Set by the owning Variants delegate to this strip's screen.
  property var modelData
  screen: modelData

  // Leave the top-right hot corner to Bar/HotCorner.
  property int cornerReserve: 80
  property int stripHeight: 4

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
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Item {
    anchors.fill: parent

    HoverHandler {
      onHoveredChanged: hovered ? root.hoverEntered() : root.hoverExited()
    }
  }
}
