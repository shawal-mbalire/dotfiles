import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../adapters"

// Audio menu: main volume slider, output devices, per-app mixer.
// Inputs are collapsed behind a toggle since most laptop users never switch mics.
BaseMenu {
    id: root

    readonly property var sink: Audio.defaultSink
    readonly property var sinkAudio: Audio.defaultSinkAudio
    property bool showInputs: false
    readonly property bool singleOutput: Audio.outputGroups.length <= 1
        && Audio.outputGroups.length > 0
        && Audio.outputGroups[0].nodes.length <= 1

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
        accent: WallpaperColors.accent
        onMoved: value => {
            if (sinkAudio) {
                sinkAudio.muted = false;
                Audio.setVolume(root.sink, value);
            }
        }
    }

    // ── Output devices ────────────────────────────────────────────────
    SectionLabel {
        label: "Outputs"
        visible: !root.singleOutput
    }

    Repeater {
        model: root.singleOutput ? [] : Audio.outputGroups
        AudioGroupSection {
            required property var modelData
            group: modelData
            sinks: true
        }
    }

    // ── Per-app volume ────────────────────────────────────────────────
    SectionLabel { label: "Apps" }

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
                    accent: WallpaperColors.accent
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

    // ── Inputs (collapsed) ───────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.menuCompactRowHeight
        radius: Theme.radius
        color: inputToggleHover.pressed ? Theme.tint(Theme.surface0, 0.6)
             : inputToggleHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
             : Theme.tint(Theme.surface0, 0.5)
        border.width: 1
        border.color: Theme.tint(Theme.surface1, 0.85)

        Behavior on color { ColorAnimation { duration: 80 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                text: root.showInputs ? "Hide inputs" : "Show inputs"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.subtext0
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.showInputs ? "\uF077" : "\uF078"
                font.family: Theme.iconFontFamily
                font.pixelSize: 10
                color: Theme.subtext0
            }
        }

        MouseArea {
            id: inputToggleHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showInputs = !root.showInputs
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.showInputs
        spacing: 8

        SectionLabel { label: "Inputs" }

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
    }
}
