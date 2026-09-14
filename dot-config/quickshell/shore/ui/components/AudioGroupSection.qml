import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// One sound card inside the audio menu: a header with the card name when it
// exposes several ports, then a row per port. Multi-port cards (onboard audio
// with Speaker + HDMI 1-3) collapse under one device instead of flooding the
// list; single-node devices (Bluetooth, network sinks) render as a lone row.
ColumnLayout {
    id: root

    required property var group
    required property bool sinks

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 6
        visible: root.group.nodes.length > 1

        Text {
            text: root.group.icon
            font.family: Theme.iconFontFamily
            font.pixelSize: 12
            color: Theme.overlay1
        }

        Text {
            Layout.fillWidth: true
            text: root.group.label
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.subtext0
        }
    }

    Repeater {
        model: root.group.nodes

        AudioDeviceRow {
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: root.group.nodes.length > 1 ? 10 : 0
            node: modelData
            selected: root.sinks
                ? modelData.id === Audio.sinkId
                : modelData.id === Audio.sourceId
            onActivate: root.sinks
                ? Audio.setDefaultSink(modelData)
                : Audio.setDefaultSource(modelData)
        }
    }
}
