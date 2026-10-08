// NightLightPort over gammastep (no typed API exists). gammastep is also
// autostarted by Hyprland, so state is re-read on a slow cadence and on demand
// rather than every few seconds per bar.
import QtQml
import Quickshell
import Quickshell.Io
import "../../../domain/ports"

NightLightPort {
  id: root

  required property int temperature
  property int refreshInterval: 15000

  function setActive(value) {
    if (value === active) return
    active = value
    if (value) Quickshell.execDetached(["gammastep", "-m", "wayland", "-O", String(temperature)])
    else Quickshell.execDetached(["pkill", "-x", "gammastep"])
    verifyTimer.restart()
  }

  function refresh() {
    if (!checkProc.running) checkProc.running = true
  }

  Process {
    id: checkProc
    command: ["pgrep", "-x", "gammastep"]
    // pgrep: 0 = found, 1 = none, anything else is a real failure.
    onExited: exitCode => {
      if (exitCode > 1) console.warn("[nightlight] pgrep exited with", exitCode)
      else root.active = exitCode === 0
    }
  }

  Timer {
    id: verifyTimer
    interval: 500
    onTriggered: root.refresh()
  }

  Timer {
    interval: root.refreshInterval
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()
}
