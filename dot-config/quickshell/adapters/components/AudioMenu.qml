import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

// Audio menu: main volume slider, per-app mixer, inputs.
BaseMenu {
    id: root

    readonly property var sink: Audio.defaultSink
    readonly property var sinkAudio: Audio.defaultSinkAudio

    // ── Output volume ─────────────────────────────────────────────────
    MenuTitle {
        title: "Audio"
        subtitle: root.sink ? (root.sink.description || root.sink.name || "")
                            : "No device"
    }

    SliderRow {
        Layout.fillWidth: true
        icon: sinkAudio && sinkAudio.muted ? Theme.iconVolumeMuted : Theme.iconVolume
        value: sinkAudio ? Math.min(sinkAudio.volume, 1.0) : 0
        label: sinkAudio ? Math.round(sinkAudio.volume * 100) + "%" : "--"
        accent: Theme.sapphire
        onMoved: value => {
            if (sinkAudio) {
                sinkAudio.muted = false;
                Audio.setVolume(root.sink, value);
            }
        }
    }


    // ── Output devices ────────────────────────────────────────────────
    Text {
        Layout.fillWidth: true
        text: "Outputs"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        color: Theme.overlay0
    }

    Repeater {
        model: Audio.outputGroups
        AudioGroupSection {
            required property var modelData
            group: modelData
            sinks: true
        }
    }


    // ── Per-app volume ────────────────────────────────────────────────
    Text {
        Layout.fillWidth: true
        text: "Apps"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        color: Theme.overlay0
    }

    Repeater {
        model: Audio.streams

        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: streamCol.implicitHeight + 10
            radius: Theme.radius
            color: Theme.tint(Theme.surface0, 0.85)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.85)

            ColumnLayout {
                id: streamCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || modelData.description || "Stream"
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.text
                    }

                    Text {
                        text: modelData.audio && modelData.audio.muted ? "muted"
                            : modelData.audio ? Math.round(modelData.audio.volume * 100) + "%"
                            : "--"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.overlay0
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    value: modelData.audio ? Math.min(modelData.audio.volume, 1.0) : 0
                    accent: Theme.sapphire
                    onMoved: value => {
                        if (modelData.audio) {
                            modelData.audio.muted = false;
                            modelData.audio.volume = value;
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Audio.streams.length === 0
        text: "No apps playing audio"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }


    // ── Inputs ────────────────────────────────────────────────────────
    Text {
        Layout.fillWidth: true
        text: "Inputs"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
        color: Theme.overlay0
    }

    Repeater {
        model: Audio.inputGroups
        AudioGroupSection {
            required property var modelData
            group: modelData
            sinks: false
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Audio.inputGroups.length === 0
        text: "No input devices"
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.overlay0
    }


    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4

        Item { Layout.fillWidth: true }

        MenuButton {
            label: "Audio effects"
            onClicked: Audio.openTweaker()
        }
    }
}
