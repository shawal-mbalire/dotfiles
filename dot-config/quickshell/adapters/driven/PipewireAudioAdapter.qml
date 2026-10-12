// AudioPort over Quickshell.Services.Pipewire. Writes go straight to the
// node's audio object, so no wpctl process is spawned per slider tick.
//
// The default sink is whatever WirePlumber picks, and it moves when a sink
// appears or disappears. AirPlay sinks, the Mac mini included, are never used
// (domain/models/Sinks.qml). If the default is one of them, or there is none,
// this adapter steers the default to the preferred sink, or else the first
// eligible one. An eligible default is left alone, so a manual choice sticks,
// except that a Bluetooth sink becomes the default when it connects.
import QtQml
import Quickshell.Services.Pipewire
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

AudioPort {
  id: root

  property int maxVolume: Bounds.volumeMax
  // node.name of the preferred sink; "" means the first eligible sink.
  property string preferredSink: ""

  readonly property var sink: Pipewire.defaultAudioSink
  // Every audio sink, tracked so names and descriptions are valid.
  // Streams are apps playing audio (Zen, a music player) and are never output devices,
  // even though Quickshell reports them as sinks.
  readonly property var allSinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio !== null)
  // Sinks the shell may use as output.
  readonly property var sinkNodes: allSinks.filter(n => Sinks.isEligible(n.name, n.description))
  readonly property bool defaultEligible: sink !== null && Sinks.isEligible(sink.name, sink.description)
  readonly property var fallback: {
    const preferred = preferredSink !== "" ? sinkNodes.find(n => n.name === preferredSink) : undefined
    return preferred ?? sinkNodes[0] ?? null
  }

  // Inputs (microphones). Streams that record from the shell's apps are not devices.
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var allSources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio !== null)
  readonly property var sourceNodes: allSources.filter(n => Sources.isEligible(n.name))

  ready: sink !== null && sink.ready && sink.audio !== null
  muted: ready && sink.audio.muted
  volume: measuredVolume()
  sinkName: sink !== null ? sink.name : ""
  sinks: sinkNodes.map(n => ({ name: n.name, label: n.description !== "" ? n.description : n.name }))
  sourceName: source !== null ? source.name : ""
  sources: sourceNodes.map(n => ({ name: n.name, label: n.description !== "" ? n.description : n.name }))

  // Sink names seen last time, so a newly connected Bluetooth sink is noticed.
  property var knownSinks: []
  onSinkNodesChanged: {
    const names = sinkNodes.map(n => n.name)
    const arrived = Sinks.arrivedBluetooth(knownSinks, names)
    knownSinks = names
    if (arrived === "" || arrived === sinkName) return
    console.log("[audio] bluetooth sink connected, switching to:", arrived)
    Pipewire.preferredDefaultAudioSink = sinkNodes.find(n => n.name === arrived)
  }

  onSinkNameChanged: console.log("[audio] default sink:", sinkName !== "" ? sinkName : "none")
  onReadyChanged: if (!ready) console.warn("[audio] no usable default sink; output is silent")

  // Moves the default off an excluded sink, or onto one when there is none.
  Binding {
    target: Pipewire
    property: "preferredDefaultAudioSink"
    value: root.fallback
    // Only after the initial sync: before it the default reads as null, and steering
    // then would overwrite the saved default (e.g. the Bluetooth speaker) with the fallback.
    when: Pipewire.ready && !root.defaultEligible && root.fallback !== null
    // Leave the last value when released; restoring would undo a later choice.
    restoreMode: Binding.RestoreNone
  }

  // Postcondition: the node reports a finite, non-negative volume.
  function measuredVolume() {
    if (!ready) return 0
    const volume = sink.audio.volume
    Errors.postcondition(Contracts.isNonNegative(volume), "audio.volume-invalid",
                         "node volume is not a finite non-negative number", { volume: volume })
    return Math.round(volume * 100)
  }

  // Pre: percent is finite, >= 0, and not above max(maxVolume, volume). Lowering is
  // always allowed, so a sink already boosted past the ceiling can still be turned down.
  function setVolume(percent) {
    Errors.precondition(Contracts.isInRange(percent, 0, Math.max(maxVolume, volume)), "audio.volume-range",
                        "volume may not be raised above the ceiling", { percent: percent, max: maxVolume })
    if (!ready) {
      console.warn("[audio] setVolume ignored: no default sink")
      return
    }
    sink.audio.volume = percent / 100
  }

  // Pre: delta is finite. Moves the level, clamped to 0..ceiling; a level already
  // above the ceiling can still be lowered by a step.
  function step(delta) {
    Errors.precondition(Number.isFinite(delta), "audio.step-type",
                        "step must be a finite number", { delta: delta })
    setVolume(Math.max(0, Math.min(maxVolume, volume + delta)))
  }

  function toggleSourceMuted() {
    if (!source || !source.audio) {
      console.warn("[audio] toggleSourceMuted ignored: no default input")
      return
    }
    source.audio.muted = !source.audio.muted
  }

  // Pre: value is a boolean.
  function setMuted(value) {
    Errors.precondition(Contracts.isBool(value), "audio.muted-type",
                        "muted must be a boolean", { value: value })
    if (!ready) {
      console.warn("[audio] setMuted ignored: no default sink")
      return
    }
    sink.audio.muted = value
  }

  // Pre: name is the name of an eligible sink in `sinks`. Applied now and kept as the
  // preferred sink for the fallback.
  function setDefaultSink(name) {
    Errors.precondition(Contracts.isOneOf(name, sinks.map(s => s.name)), "audio.sink-unknown",
                        "sink must be one of the eligible audio sinks", { name: name })
    preferredSink = name
    Pipewire.preferredDefaultAudioSink = sinkNodes.find(n => n.name === name)
  }

  // Pre: name is the name of an eligible input in `sources`. Applied now and kept as
  // the preferred input while it is present.
  function setDefaultSource(name) {
    Errors.precondition(Contracts.isOneOf(name, sources.map(s => s.name)), "audio.source-unknown",
                        "source must be one of the eligible audio inputs", { name: name })
    Pipewire.preferredDefaultAudioSource = sourceNodes.find(n => n.name === name)
  }

  // Binds every audio sink and input so names, descriptions and audio properties are live.
  PwObjectTracker {
    objects: root.allSinks.concat(root.allSources)
  }
}
