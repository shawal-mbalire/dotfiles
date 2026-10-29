import QtQml
import Quickshell.Io
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

BrightnessPort {
  id: root
  required property string device
  property int pollInterval: 2000; property int settleInterval: 1500; property int confirmTolerance: 1
  readonly property string sysfsDir: "/sys/class/backlight/" + device
  readonly property int maxRaw: parseInt(maxFile.text()) || 0
  readonly property int measured: measuredPercent()

  function measuredPercent() {
    if (maxRaw <= 0) return 0
    const raw = parseInt(curFile.text()) || 0
    Errors.postcondition(raw >= 0 && raw <= maxRaw, "brightness.raw-range", "current brightness is outside 0..max_brightness", { raw: raw, max: maxRaw })
    return BrightnessCurve.percentOf(raw, maxRaw)
  }

  property int requested: -1
  property int pending: -1
  available: maxRaw > 0
  percent: requested >= 0 ? requested : measured

  function setPercent(val) {
    Errors.precondition(Contracts.isInRange(val, Bounds.percentMin, Bounds.percentMax), "brightness.percent-range", "percent must be within 0..100", { value: val })
    if (!available) return
    const clamped = Math.round(val)
    requested = clamped
    if (setProc.running) pending = clamped
    else write(clamped)
  }

  function step(delta) {
    Errors.precondition(Number.isFinite(delta), "brightness.step-type", "step must be a finite number", { delta: delta })
    setPercent(Math.max(Bounds.percentMin, Math.min(Bounds.percentMax, percent + delta)))
  }

  function write(val) {
    settleTimer.restart()
    setProc.exec(["brightnessctl", "--device", device, "-e" + Bounds.brightnessExponent, "-n" + Bounds.brightnessMinRaw, "set", val + "%"])
  }
  function refresh() { curFile.reload() }
  function onReadBack() {
    if (setProc.running || pending >= 0) return
    if (requested < 0 || Math.abs(measuredPercent() - requested) <= confirmTolerance) requested = -1
  }

  FileView { id: curFile; path: root.sysfsDir + "/brightness"; onLoaded: root.onReadBack() }
  FileView { id: maxFile; path: root.sysfsDir + "/max_brightness" }

  Timer { interval: root.pollInterval; running: root.available; repeat: true; onTriggered: curFile.reload() }
  Timer { id: settleTimer; interval: root.settleInterval; onTriggered: if (!setProc.running && root.pending < 0) root.requested = -1 }

  Process {
    id: setProc
    onExited: exitCode => {
      if (root.pending >= 0) { const next = root.pending; root.pending = -1; root.write(next) }
      else curFile.reload()
    }
  }
}
