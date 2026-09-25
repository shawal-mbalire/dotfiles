import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root 
  spacing: 7 

  property var sink: Pipewire.defaultAudioSink

  readonly property bool ready: sink && sink.ready 
  readonly property bool muted: ready && sink.audio.muted 
  readonly property int volume: ready ? Math.round(sink.audio.volume * 100) : 0

  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xf0581)
    if (muted) return String.fromCodePoint(0xf075f)
    if (volume === 0) return String.fromCodePoint(0xf0581)
    if (volume < 34) return String.fromCodePoint(0xf057f)
    if (volume < 67) return String.fromCodePoint(0xf0580)

    return String.fromCodePoint(0xf057e)
  }

  Text {
    text: root.icon
    color: "#f5cd5b"
    font {
      family: "Comfortaa"
      pixelSize: 15
      weight: 1000
    }
  }
  Text {
    text: {
      if (!root.ready) return "_"
      if (root.muted) return "Muted"

      return root.volume + "%"
    }
    color: root .muted? "#c4b09a" : "#f5e2c5"
    font {
      family: "Comfortaa"
      pixelSize: 15
      weight: 1000
    }
  }
 
  PwObjectTracker {
    objects: [root.sink]
  }
}
