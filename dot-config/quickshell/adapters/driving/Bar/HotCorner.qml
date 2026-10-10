// The top-right hot corner, a dedicated layer-shell surface.
//
// Hovering the zone reveals the bar at once. Opening the control center needs a
// deliberate dwell: the pointer has to stay in the zone for `dwellMs`. A brush
// across the corner (on the way to a window's close button, say) does nothing.
// Each visit fires `triggered()` at most once, and leaving re-arms it.
// It is a separate surface from the top-edge strip (which reserves this width),
// so corner detection never depends on hit-testing math or stacking order.
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
  property int dwellMs: 180

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

  Timer {
    id: dwell
    interval: root.dwellMs
    onTriggered: if (hover.hovered) root.triggered()
  }

  Item {
    anchors.fill: parent

    HoverHandler {
      id: hover
      onHoveredChanged: {
        if (hovered) {
          root.hoverEntered()
          dwell.restart()
        } else {
          dwell.stop()
          root.hoverExited()
        }
      }
    }
  }
}
