// BrightnessPort: reads /sys/class/backlight/<device>, writes via brightnessctl.
// sysfs files never emit inotify events, so one shared adapter polls the file
// (a cheap read, no process) instead of every bar and the control center
// each running their own loop.
import QtQml
import Quickshell.Io
import "../../../domain/ports"

BrightnessPort {
  id: root

  required property string device
  property int pollInterval: 500

  readonly property string sysfsDir: "/sys/class/backlight/" + device
  readonly property int maxRaw: parseInt(maxFile.text()) || 0
  readonly property int measured: maxRaw > 0 ? Math.round((parseInt(curFile.text()) || 0) * 100 / maxRaw) : 0

  // Optimistic value while a write is in flight, so a dragged slider does not
  // jump back to the last polled value. -1 means "use the measured value".
  property int requested: -1
  property int pending: -1

  available: maxRaw > 0
  percent: requested >= 0 ? requested : measured

  function setPercent(value) {
    if (!available || !Number.isFinite(value)) return
    const clamped = Math.max(0, Math.min(100, Math.round(value)))
    requested = clamped
    // Coalesce: a slider drag fires far faster than brightnessctl finishes.
    if (setProc.running) pending = clamped
    else write(clamped)
  }

  function write(value) {
    setProc.exec(["brightnessctl", "--device", device, "set", value + "%"])
  }

  FileView {
    id: curFile
    path: root.sysfsDir + "/brightness"
    onLoaded: if (!setProc.running && root.pending < 0) root.requested = -1
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
