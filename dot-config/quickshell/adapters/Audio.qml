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

    // Cached filter results — recomputed only when Pipewire.nodes.values changes.
    property var _nodes: []
    property var _streams: []
    property var _outputGroups: []
    property var _inputGroups: []
    property int _nodeRevision: 0

    readonly property var nodes: root._nodes
    readonly property var streams: root._streams

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
    readonly property var defaultSinkAudio: root.defaultSink ? root.defaultSink.audio : null
    readonly property var defaultSourceAudio: root.defaultSource ? root.defaultSource.audio : null

    readonly property int sinkId: root.defaultSink ? root.defaultSink.id : -1
    readonly property int sourceId: root.defaultSource ? root.defaultSource.id : -1

    readonly property var outputGroups: root._outputGroups
    readonly property var inputGroups: root._inputGroups

    function _recomputeNodes() {
        const all = Pipewire.nodes.values;
        const nodes = [];
        const streams = [];
        for (let i = 0; i < all.length; i++) {
            const n = all[i];
            if (!n.audio) continue;
            if (n.isStream) streams.push(n);
            else nodes.push(n);
        }
        root._nodes = nodes;
        root._streams = streams;
        root._outputGroups = AudioGroups.groupByDevice(
            nodes.filter(n => n.isSink), root.sinkId);
        root._inputGroups = AudioGroups.groupByDevice(
            nodes.filter(n => !n.isSink), root.sourceId);
        root._nodeRevision++;
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root._recomputeNodes(); }
    }

    Connections {
        target: root
        function onSinkIdChanged() { root._recomputeNodes(); }
        function onSourceIdChanged() { root._recomputeNodes(); }
    }

    Component.onCompleted: _recomputeNodes()

    // Bind every node so its audio iface stays readable/writable.
    PwObjectTracker {
        objects: root._nodes
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
