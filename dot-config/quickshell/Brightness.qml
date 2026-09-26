import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 7

  readonly property string device: "intel_backlight"

  readonly property int maxBrightness: parseInt(maxFile.text())
  readonly property real percent: maxBrightness > 0 ? parseInt(curFile.text()) / maxBrightness : 0
  readonly property int brightness: Math.round(percent * 100)

  readonly property string icon: {
    if (brightness === 0) return String.fromCodePoint(0xF0591)
    if (brightness < 34) return String.fromCodePoint(0xF0592)
    if (brightness < 67) return String.fromCodePoint(0xF183F)
    return String.fromCodePoint(0xF0590)
  }

  FileView {
    id: curFile
    path: `/sys/class/backlight/${root.device}/brightness`
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: maxFile
    path: `/sys/class/backlight/${root.device}/max_brightness`
  }

  function setBrightness(pct: int): void {
    const val = Math.round((pct / 100) * maxBrightness)
    Quickshell.execDetached(["sh", "-c", `echo ${val} > /sys/class/backlight/${root.device}/brightness`])
  }

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
    color: colorYellow
    font {
      family: themeNerdFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
  }

  Text {
    text: root.brightness + "%"
    color: colorText
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
  }
}
