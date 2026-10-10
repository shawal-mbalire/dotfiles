import "../../../infra/config"
import "../Shared"
import "../../../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 7

  required property BrightnessPort brightnessPort
  property int scrollStep: 5

  // NB: must not be named `brightness` — that shadows the adapter id in
  // shell.qml and stops the port from being injected (see AGENTS.md §7).
  readonly property int level: brightnessPort.percent

  visible: brightnessPort.available

  readonly property string icon: {
    if (level === 0) return String.fromCodePoint(0xF00DA)
    if (level < 34) return String.fromCodePoint(0xF00DC)
    if (level < 67) return String.fromCodePoint(0xF00DE)
    return String.fromCodePoint(0xF00E0)
  }

  Text {
    text: root.icon
    color: root.level === 0 ? Theme.overlay0 : Theme.yellow
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  Text {
    text: root.level + "%"
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  // Scroll to adjust.
  WheelHandler {
    onWheel: event => {
      const step = event.angleDelta.y > 0 ? root.scrollStep : -root.scrollStep
      root.brightnessPort.setPercent(Math.max(0, Math.min(100, root.level + step)))
    }
  }
}
