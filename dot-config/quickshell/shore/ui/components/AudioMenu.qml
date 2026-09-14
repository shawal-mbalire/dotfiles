import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Output + input device management. Rows select the default device and expose
// per-device volume/mute natively through Pipewire.
ColumnLayout {
    id: root

    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var sinks: devices.filter(n => n.isSink)
    readonly property var sources: devices.filter(n => !n.isSink)
    readonly property int sinkId: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.id : -1
    readonly property int sourceId: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.id : -1

    implicitWidth: 296
    spacing: 6

    // Bind every device so its audio iface is readable/writable.
    PwObjectTracker {
        objects: root.devices
    }

    MenuTitle {
        title: "Audio"
        subtitle: root.sinks.length + " outputs · " + root.sources.length + " inputs"
    }

    SectionLabel {
        Layout.topMargin: 2
        label: "Outputs"
    }

    Repeater {
        model: root.sinks
        AudioDeviceRow {
            required property var modelData
            Layout.fillWidth: true
            node: modelData
            selected: modelData.id === root.sinkId
            onActivate: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.sinks.length === 0
        text: "No output devices"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 1
        color: Theme.tint(Theme.surface1, 0.5)
    }

    SectionLabel {
        Layout.topMargin: 4
        label: "Inputs"
    }

    Repeater {
        model: root.sources
        AudioDeviceRow {
            required property var modelData
            Layout.fillWidth: true
            node: modelData
            selected: modelData.id === root.sourceId
            onActivate: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.sources.length === 0
        text: "No input devices"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }
}
