// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/
// Adapters/Driven/Backlight/BacklightAdapter.qml
// Driven adapter: BrightnessPort ← Linux backlight.
//   read  — sysfs /sys/class/backlight/<device>/{brightness,max_brightness}
//   write — brightnessctl (logind/polkit)
// The device is discovered at runtime instead of hardcoding "intel_backlight",
// so this works on AMD/ACPI backlights too. sysfs has no inotify, so we poll.
import Quickshell
import Quickshell.Io
import QtQuick
import "../../../Domain/Ports"

BrightnessPort {
  id: root

  property string device: ""

  readonly property string currentPath: device !== "" ? `/sys/class/backlight/${device}/brightness` : ""
  readonly property string maxPath: device !== "" ? `/sys/class/backlight/${device}/max_brightness` : ""

  level: maxLevel > 0 ? Math.round(rawLevel / maxLevel * 100) : 0

  readonly property int maxLevel: parseInt(maxFile.text()) || 0
  readonly property int rawLevel: parseInt(curFile.text()) || 0

  Process {
    id: detectProc
    command: ["bash", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/brightness\" ] && basename \"$d\" && break; done"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.device = text.trim()
    }
  }

  FileView {
    id: curFile
    path: root.currentPath
  }

  FileView {
    id: maxFile
    path: root.maxPath
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      if (root.device === "") {
        if (!detectProc.running) detectProc.running = true
        return
      }
      curFile.reload()
      if (root.maxLevel === 0) maxFile.reload()
    }
  }

  Component.onCompleted: if (!detectProc.running) detectProc.running = true

  Process {
    id: setProc
    running: false
    onExited: curFile.reload()
  }

  function setLevel(value) {
    const v = Math.max(0, Math.min(100, Math.round(value)))
    setProc.command = ["brightnessctl", "set", v + "%"]
    setProc.running = false
    setProc.running = true
  }
}
