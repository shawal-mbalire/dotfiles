// ColorCorrectionPort over gammastep (no typed API exists). gammastep is also
// autostarted by Hyprland, so state is re-read on a slow cadence and on demand
// rather than every few seconds per bar.
import QtQml
import Quickshell
import Quickshell.Io
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

ColorCorrectionPort {
  id: root

  required property int temperature
  property int refreshInterval: 60000

  // Pre: temperature is a gammastep colour temperature (checked once at startup).
  Component.onCompleted: {
    Errors.precondition(Contracts.isInRange(temperature, Bounds.colorTemperatureMin, Bounds.colorTemperatureMax),
                        "color-correction.temperature-range", "temperature must be a gammastep colour temperature",
                        { temperature: temperature })
    refresh()
  }

  // Pre: value is a boolean.
  function setActive(value) {
    Errors.precondition(Contracts.isBool(value), "color-correction.active-type",
                        "active must be a boolean", { value: value })
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
      if (exitCode > 1) console.warn("[color-correction] pgrep exited with", exitCode)
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
}
