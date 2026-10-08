import "../Shared"
import "../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 7

  required property BrightnessPort brightnessPort
  property int scrollStep: 5

  readonly property int brightness: brightnessPort.percent

  visible: brightnessPort.available

  readonly property string icon: {
    if (brightness === 0) return String.fromCodePoint(0xF00DA)
    if (brightness < 34) return String.fromCodePoint(0xF00DC)
    if (brightness < 67) return String.fromCodePoint(0xF00DE)
    return String.fromCodePoint(0xF00E0)
  }

  Text {
    text: root.icon
    color: root.brightness === 0 ? Theme.overlay0 : Theme.yellow
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  Text {
    text: root.brightness + "%"
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  // Scroll to adjust.
  WheelHandler {
    onWheel: event => {
      const step = event.angleDelta.y > 0 ? root.scrollStep : -root.scrollStep
      root.brightnessPort.setPercent(Math.max(0, Math.min(100, root.brightness + step)))
    }
  }
}
