// The top-right hot corner, a dedicated layer-shell surface.
//
// Its whole job is reliability: hovering anywhere in this zone always reveals
// the bar *and* opens the control center together. It is a separate surface
// from the top-edge strip (which reserves this width) so corner detection never
// depends on hit-testing math or surface stacking order.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  // Set by the owning Variants delegate to this corner's screen.
  property var modelData
  screen: modelData

  property int zoneWidth: 80
  property int zoneHeight: 4

  signal hoverEntered()
  signal hoverExited()
  signal triggered()

  anchors {
    top: true
    right: true
  }

  implicitWidth: root.zoneWidth
  implicitHeight: root.zoneHeight
  color: "transparent"
  exclusiveZone: 0
  WlrLayershell.namespace: "quickshell:hot-corner"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Item {
    anchors.fill: parent

    HoverHandler {
      onHoveredChanged: {
        if (hovered) {
          root.hoverEntered()
          root.triggered()
        } else {
          root.hoverExited()
        }
      }
    }
  }
}
