import Quickshell.Hyprland
import QtQuick

// Emits dismissed() when the user clicks outside `window`.
//
// Activating a focus grab in the same frame the surface maps races Hyprland,
// which clears it immediately — the popup would open and instantly close
// (this broke SUPER+N). So the grab is armed shortly after the window shows,
// and only a clear that follows a grab that really started counts. A grab the
// compositor rejects is re-armed a few times; if it never engages the popup
// simply stays open (Escape / the keybind still close it).
HyprlandFocusGrab {
  id: root

  required property var window
  property bool enabled: true
  property int armDelay: 60
  property bool engaged: false
  property int maxAttempts: 4
  property int attempts: 0

  signal dismissed()

  windows: [window]

  onActiveChanged: if (active) engaged = true

  onCleared: {
    const wasEngaged = engaged
    engaged = false
    if (!enabled || !window.visible) return
    if (wasEngaged) dismissed()
    else if (attempts < maxAttempts) armTimer.restart()
  }

  onEnabledChanged: if (!enabled) active = false

  property Timer armTimer: Timer {
    interval: root.armDelay
    running: root.enabled && root.window.visible
    onTriggered: {
      root.attempts++
      root.active = true
    }
  }
}
