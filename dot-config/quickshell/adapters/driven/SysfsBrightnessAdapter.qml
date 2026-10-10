// BrightnessPort: reads /sys/class/backlight/<device>, writes via brightnessctl.
// sysfs files never emit inotify events, so one shared adapter polls the file
// (a cheap read, no process) instead of every bar and the control center
// each running their own loop. The Hyprland keys push a refresh over IPC after
// they change the level, so the poll is only a fallback for other writers.
// Percent is on brightnessctl's perceptual curve (-e4), the one the keys use
// (domain/models/BrightnessCurve.qml).
import QtQml
import Quickshell.Io
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

BrightnessPort {
  id: root

  required property string device
  property int pollInterval: 2000
  // How long an unconfirmed optimistic value may stand before the reading is trusted.
  property int settleInterval: 1500
  // Points of rounding a readback may differ from the request and still confirm it.
  property int confirmTolerance: 1

  readonly property string sysfsDir: "/sys/class/backlight/" + device
  readonly property int maxRaw: parseInt(maxFile.text()) || 0
  readonly property int measured: measuredPercent()

  // Postcondition: the kernel reports a raw value within 0..max_brightness.
  function measuredPercent() {
    if (maxRaw <= 0) return 0
    const raw = parseInt(curFile.text()) || 0
    Errors.postcondition(raw >= 0 && raw <= maxRaw, "brightness.raw-range",
                         "current brightness is outside 0..max_brightness", { raw: raw, max: maxRaw })
    return BrightnessCurve.percentOf(raw, maxRaw)
  }

  // Optimistic value while a write is in flight, so a dragged slider does not
  // jump back to the last polled value. -1 means "use the measured value".
  property int requested: -1
  property int pending: -1

  available: maxRaw > 0
  percent: requested >= 0 ? requested : measured

  // Pre: value is finite and within 0..100.
  function setPercent(value) {
    Errors.precondition(Contracts.isInRange(value, Bounds.percentMin, Bounds.percentMax),
                        "brightness.percent-range", "percent must be within 0..100",
                        { value: value })
    if (!available) {
      console.warn("[brightness] setPercent ignored: no backlight device")
      return
    }
    const clamped = Math.round(value)
    requested = clamped
    // Coalesce: a slider drag fires far faster than brightnessctl finishes.
    if (setProc.running) pending = clamped
    else write(clamped)
  }

  function write(value) {
    settleTimer.restart()
    setProc.exec(["brightnessctl", "--device", device,
                  "-e" + Bounds.brightnessExponent, "-n" + Bounds.brightnessMinRaw,
                  "set", value + "%"])
  }

  function refresh() {
    curFile.reload()
  }

  // A reading confirms the optimistic value once it matches the request. Until
  // then, and while a write is in flight, the requested value stays on screen,
  // so the slider never snaps back to a stale reading between write and read.
  function onReadBack() {
    if (setProc.running || pending >= 0) return
    if (requested < 0 || Math.abs(measuredPercent() - requested) <= confirmTolerance) requested = -1
  }

  FileView {
    id: curFile
    path: root.sysfsDir + "/brightness"
    onLoaded: root.onReadBack()
    onLoadFailed: error => console.warn("[brightness] cannot read", path, error)
  }

  FileView {
    id: maxFile
    path: root.sysfsDir + "/max_brightness"
    onLoadFailed: error => console.warn("[brightness] cannot read", path, error)
  }

  Timer {
    interval: root.pollInterval
    running: root.available
    repeat: true
    onTriggered: curFile.reload()
  }

  // A write that never reads back must not pin the optimistic value forever.
  Timer {
    id: settleTimer
    interval: root.settleInterval
    onTriggered: if (!setProc.running && root.pending < 0) root.requested = -1
  }

  Process {
    id: setProc
    onExited: exitCode => {
      if (exitCode !== 0) console.warn("[brightness] brightnessctl exited with", exitCode)
      if (root.pending >= 0) {
        const next = root.pending
        root.pending = -1
        root.write(next)
      } else {
        curFile.reload()
      }
    }
  }
}
