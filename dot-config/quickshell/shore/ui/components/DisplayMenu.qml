import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Monitor management: list outputs, disable/enable, flip mirror/extend.
ColumnLayout {
    id: root

    property var monitors: []

    implicitWidth: 296
    spacing: 6

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function monitorEval(expr) {
        evalProc.command = ["hyprctl", "eval", expr];
        evalProc.running = true;
    }

    function setDisabled(name, disabled) {
        if (disabled)
            monitorEval('hl.monitor({ output = "' + name + '", disabled = true })');
        else
            monitorEval('hl.monitor({ output = "' + name + '", mode = "highres", position = "auto", scale = 1 })');
    }

    Component.onCompleted: refresh()

    Process {
        id: proc
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(out.text) || [];
                } catch (e) {
                    root.monitors = [];
                }
            }
        }
    }

    Process {
        id: evalProc
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    MenuTitle {
        title: "Displays"
        subtitle: root.monitors.length + (root.monitors.length === 1 ? " output" : " outputs")
    }

    Repeater {
        model: root.monitors

        Rectangle {
            id: row
            required property var modelData
            readonly property bool disabled: modelData.disabled === true
            readonly property string mirrorOf: String(modelData.mirrorOf || "none")

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + 12
            radius: Theme.radius
            color: disabled ? Theme.tint(Theme.surface0, 0.25) : Theme.tint(Theme.surface0, 0.5)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.5)

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: row.disabled ? Theme.overlay0 : Theme.text
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Formatters.monitorDetail(row.modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.subtext0
                        }
                    }

                    MenuButton {
                        visible: !row.disabled && root.monitors.length > 1
                        label: "Disable"
                        onClicked: root.setDisabled(row.modelData.name, true)
                    }

                    MenuButton {
                        visible: row.disabled
                        label: "Enable"
                        onClicked: root.setDisabled(row.modelData.name, false)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Formatters.isMirroring(row.modelData)
                    text: "mirroring " + row.mirrorOf
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.mauve
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 1
        color: Theme.tint(Theme.surface1, 0.5)
    }

    MenuButton {
        Layout.fillWidth: true
        label: "Mirror / Extend"
        onClicked: Quickshell.execDetached([Config.displayToggle])
    }
}
