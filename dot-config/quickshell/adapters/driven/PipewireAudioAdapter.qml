// AudioPort over Quickshell.Services.Pipewire. Writes go straight to the
// node's audio object, so no wpctl process is spawned per slider tick.
import QtQml
import Quickshell.Services.Pipewire
import "../../domain/ports"

AudioPort {
  id: root

  property int maxVolume: 150

  readonly property var sink: Pipewire.defaultAudioSink

  ready: sink !== null && sink.ready && sink.audio !== null
  muted: ready && sink.audio.muted
  volume: ready ? Math.round(sink.audio.volume * 100) : 0

  function setVolume(percent) {
    if (!ready || !Number.isFinite(percent)) return
    sink.audio.volume = Math.max(0, Math.min(maxVolume, Math.round(percent))) / 100
  }

  function setMuted(value) {
    if (!ready) return
    sink.audio.muted = value
  }

  // Binds the sink so its audio properties are live.
  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }
}
