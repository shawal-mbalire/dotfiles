import "../Shared"
import "../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 7

  required property AudioPort audioPort
  property int scrollStep: 5
  property int scrollMax: 100

  readonly property bool ready: audioPort.ready
  readonly property bool muted: audioPort.muted
  readonly property int volume: audioPort.volume

  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xF0581)
    if (muted) return String.fromCodePoint(0xF075F)
    if (volume === 0) return String.fromCodePoint(0xF0581)
    if (volume < 34) return String.fromCodePoint(0xF057F)
    if (volume < 67) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }

  Text {
    text: root.icon
    color: root.muted ? Theme.overlay1 : Theme.yellow
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  Text {
    text: !root.ready ? "_" : root.muted ? "Muted" : root.volume + "%"
    color: root.muted ? Theme.overlay1 : Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  // Click toggles mute, scroll adjusts (capped at 100% from the bar; the
  // control center slider can go higher).
  TapHandler {
    cursorShape: Qt.PointingHandCursor
    onTapped: root.audioPort.setMuted(!root.muted)
  }

  WheelHandler {
    onWheel: event => {
      const step = event.angleDelta.y > 0 ? root.scrollStep : -root.scrollStep
      const target = Math.max(0, Math.min(Math.max(root.scrollMax, root.volume), root.volume + step))
      root.audioPort.setVolume(target)
    }
  }
}
