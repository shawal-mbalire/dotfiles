import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Output + input device management. Devices are grouped under their parent
// sound card (see domain/AudioGroups.qml) so multi-port cards read as one
// device with ports. The audio adapter owns selection and volume.
ColumnLayout {
    id: root

    implicitWidth: 296
    spacing: 6

    MenuTitle {
        title: "Audio"
        subtitle: Audio.outputGroups.length + " outputs · "
            + Audio.inputGroups.length + " inputs"
    }

    SectionLabel {
        Layout.topMargin: 2
        label: "Outputs"
    }

    Repeater {
        model: Audio.outputGroups
        AudioGroupSection {
            required property var modelData
            group: modelData
            sinks: true
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Audio.outputGroups.length === 0
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

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 1
        color: Theme.tint(Theme.surface1, 0.5)
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
