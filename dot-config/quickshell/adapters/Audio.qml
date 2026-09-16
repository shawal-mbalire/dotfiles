pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../domain"
import "../infra"

// Driven adapter: audio devices (AudioPort) over Quickshell's native Pipewire
// service. Owns the card grouping (via the pure domain), default-device
// selection, per-node volume/mute, and launching the filter tweaker.
//
// The shell only ever talks to this adapter, so the Pipewire backend stays
// swappable and the UI never imports the service directly.
Singleton {
    id: root

    // Every non-stream audio node (sinks + sources).
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)

    // Audio streams (per-app volume control).
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream)

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
    readonly property var defaultSinkAudio: root.defaultSink ? root.defaultSink.audio : null
    readonly property var defaultSourceAudio: root.defaultSource ? root.defaultSource.audio : null

    readonly property int sinkId: root.defaultSink ? root.defaultSink.id : -1
    readonly property int sourceId: root.defaultSource ? root.defaultSource.id : -1

    readonly property var outputGroups: AudioGroups.groupByDevice(
        root.nodes.filter(n => n.isSink), root.sinkId)
    readonly property var inputGroups: AudioGroups.groupByDevice(
        root.nodes.filter(n => !n.isSink), root.sourceId)

    // Bind every node so its audio iface stays readable/writable.
    PwObjectTracker {
        objects: root.nodes
    }

    // ── AudioPort ─────────────────────────────────────────────────────────
    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    function toggleMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted;
    }

    function setVolume(node, value) {
        if (node && node.audio) node.audio.volume = Math.max(0, value);
    }

    function bumpVolume(node, delta) {
        if (node && node.audio)
            node.audio.volume = Math.max(0, node.audio.volume + delta);
    }

    // Filters live in EasyEffects (a PipeWire filter-chain front end); the
    // shell just launches it.
    function openTweaker() {
        Quickshell.execDetached([InfraConfig.audioTweaker]);
    }
}
