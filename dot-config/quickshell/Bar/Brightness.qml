import "../Shared"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 7

  readonly property string device: "intel_backlight"

  readonly property int maxBrightness: parseInt(maxFile.text()) || 0
  readonly property real percent: maxBrightness > 0 ? (parseInt(curFile.text()) || 0) / maxBrightness : 0
  readonly property int brightness: Math.round(percent * 100)

  readonly property string icon: {
    if (brightness === 0) return String.fromCodePoint(0xF00DA)
    if (brightness < 34) return String.fromCodePoint(0xF00DC)
    if (brightness < 67) return String.fromCodePoint(0xF00DE)
    return String.fromCodePoint(0xF00E0)
  }

  FileView {
    id: curFile
    path: `/sys/class/backlight/${root.device}/brightness`
  }

  FileView {
    id: maxFile
    path: `/sys/class/backlight/${root.device}/max_brightness`
  }

  // sysfs does not support inotify, so watchChanges never fires here — poll instead.
  Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: curFile.reload()
  }

  Component.onCompleted: {
    curFile.reload()
    maxFile.reload()
  }

  Text {
    text: root.icon
    color: root.brightness === 0 ? Theme.overlay0 : Theme.yellow
    font {
      family: Theme.nerdFont
      pixelSize: Theme.fontSize
      weight: Theme.fontWeight
    }
  }

  Text {
    text: root.brightness + "%"
    color: Theme.text
    font {
      family: Theme.font
      pixelSize: Theme.fontSize
      weight: Theme.fontWeight
    }
  }
}
