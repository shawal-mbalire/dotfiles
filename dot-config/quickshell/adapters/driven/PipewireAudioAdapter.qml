import QtQml
import Quickshell.Services.Pipewire
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

AudioPort {
  id: root
  property int maxVolume: Bounds.volumeMax
  property string preferredSink: ""

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var allSinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio !== null)
  readonly property var sinkNodes: allSinks.filter(n => Sinks.isEligible(n.name, n.description))
  readonly property bool defaultEligible: sink !== null && Sinks.isEligible(sink.name, sink.description)
  readonly property var fallback: {
    const preferred = preferredSink !== "" ? sinkNodes.find(n => n.name === preferredSink) : undefined
    return preferred ?? sinkNodes[0] ?? null
  }

  readonly property var source: Pipewire.defaultAudioSource
  readonly property var allSources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio !== null)
  readonly property var sourceNodes: allSources.filter(n => Sinks.isSourceEligible(n.name))

  ready: sink !== null && sink.ready && sink.audio !== null
  muted: ready && sink.audio.muted
  volume: measuredVolume()
  sinkName: sink !== null ? sink.name : ""
  sinks: sinkNodes.map(n => ({ name: n.name, label: n.description !== "" ? n.description : n.name }))
  sourceName: source !== null ? source.name : ""
  sources: sourceNodes.map(n => ({ name: n.name, label: n.description !== "" ? n.description : n.name }))

  property var knownSinks: []
  onSinkNodesChanged: {
    const names = sinkNodes.map(n => n.name), arrived = Sinks.arrivedBluetooth(knownSinks, names)
    knownSinks = names
    if (arrived !== "" && arrived !== sinkName) Pipewire.preferredDefaultAudioSink = sinkNodes.find(n => n.name === arrived)
  }

  Binding {
    target: Pipewire; property: "preferredDefaultAudioSink"; value: root.fallback
    when: Pipewire.ready && !root.defaultEligible && root.fallback !== null; restoreMode: Binding.RestoreNone
  }

  function measuredVolume() {
    if (!ready) return 0
    const vol = sink.audio.volume
    Errors.postcondition(Contracts.isNonNegative(vol), "audio.volume-invalid", "node volume is not a finite non-negative number", { volume: vol })
    return Math.round(vol * 100)
  }

  function setVolume(pct) {
    Errors.precondition(Contracts.isInRange(pct, 0, Math.max(maxVolume, volume)), "audio.volume-range", "volume may not be raised above the ceiling", { percent: pct, max: maxVolume })
    if (ready) sink.audio.volume = pct / 100
  }

  function step(delta) {
    Errors.precondition(Number.isFinite(delta), "audio.step-type", "step must be a finite number", { delta: delta })
    setVolume(Math.max(0, Math.min(maxVolume, volume + delta)))
  }

  function toggleSourceMuted() { if (source && source.audio) source.audio.muted = !source.audio.muted }
  function setMuted(val) {
    Errors.precondition(Contracts.isBool(val), "audio.muted-type", "muted must be a boolean", { value: val })
    if (ready) sink.audio.muted = val
  }
  function setDefaultSink(nm) {
    Errors.precondition(Contracts.isOneOf(nm, sinks.map(s => s.name)), "audio.sink-unknown", "sink must be one of the eligible audio sinks", { name: nm })
    preferredSink = nm; Pipewire.preferredDefaultAudioSink = sinkNodes.find(n => n.name === nm)
  }
  function setDefaultSource(nm) {
    Errors.precondition(Contracts.isOneOf(nm, sources.map(s => s.name)), "audio.source-unknown", "source must be one of the eligible audio inputs", { name: nm })
    Pipewire.preferredDefaultAudioSource = sourceNodes.find(n => n.name === nm)
  }

  PwObjectTracker { objects: root.allSinks.concat(root.allSources) }
}
