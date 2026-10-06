// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Pipewire/PwNodeAudio
// Adapters/Driven/Pipewire/PipewireAudioAdapter.qml
// Driven adapter: AudioPort ← Pipewire. Reads the default sink and writes
// volume/mute through it (requires the PwObjectTracker binding below).
import Quickshell.Services.Pipewire
import "../../../Domain/Ports"

AudioPort {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink

  ready: sink !== null && sink.ready
  muted: ready && sink.audio.muted
  volume: ready ? Math.round(sink.audio.volume * 100) : 0

  function setVolume(value) {
    if (!ready) return
    sink.audio.volume = Math.max(0, Math.min(150, Math.round(value))) / 100
  }

  function setMuted(value) {
    if (!ready) return
    sink.audio.muted = value
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
