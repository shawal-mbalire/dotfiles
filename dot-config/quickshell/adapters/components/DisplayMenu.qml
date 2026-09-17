import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."
import "../../domain"
import "../../adapters"

// Monitor management: list outputs, disable/enable, flip mirror/extend,
// scale presets, gamma step.  All hyprctl access lives in the Compositor
// adapter; this surface only ticks a refresh timer and renders.
BaseMenu {
    id: root

    Component.onCompleted: Compositor.refreshMonitors()

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: Compositor.refreshMonitors()
    }

    MenuTitle {
        title: "Displays"
        subtitle: Compositor.monitors.length
            + (Compositor.monitors.length === 1 ? " output" : " outputs")
    }

    Repeater {
        model: Compositor.monitors

        Rectangle {
            id: row
            required property var modelData
            readonly property bool disabled: modelData.disabled === true
            readonly property string mirrorOf: String(modelData.mirrorOf || "none")

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + 12
            radius: Theme.radius
            color: disabled ? Theme.tint(Theme.surface0, 0.85) : Theme.tint(Theme.surface0, 0.85)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.85)

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
                        visible: !row.disabled && Compositor.monitors.length > 1
                        label: "Disable"
                        onClicked: Compositor.setMonitorDisabled(row.modelData.name, true)
                    }

                    MenuButton {
                        visible: row.disabled
                        label: "Enable"
                        onClicked: Compositor.setMonitorDisabled(row.modelData.name, false)
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


    // ── Scale ─────────────────────────────────────────────────────────
    SectionLabel { label: "Scale" }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { label: "100%", scale: 1.0 },
                { label: "125%", scale: 1.25 },
                { label: "150%", scale: 1.5 }
            ]

            Rectangle {
                id: scaleBtn
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.menuCompactRowHeight
                radius: Theme.radius
                readonly property bool isActive: {
                    const mon = Compositor.monitors.length > 0 ? Compositor.monitors[0] : null;
                    const current = mon ? mon.scale : 1;
                    return Math.abs(current - modelData.scale) < 0.01;
                }
                color: isActive ? Theme.tint(WallpaperColors.accent, 0.85)
                     : scaleBtnHover.pressed ? Theme.tint(Theme.surface0, 0.6)
                     : scaleBtnHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
                     : Theme.tint(Theme.surface0, 0.5)
                border.width: 1
                border.color: Theme.tint(Theme.surface1, 0.85)

                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: scaleBtn.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: scaleBtn.isActive ? Theme.crust : Theme.text
                }

                MouseArea {
                    id: scaleBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Compositor.setScale(scaleBtn.modelData.scale)
                }
            }
        }
    }


    // ── Night light / gammastep ───────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: Theme.iconNight
            font.family: Theme.iconFontFamily
            font.pixelSize: 14
            color: Nightlight.active ? WallpaperColors.accent : Theme.overlay0
        }

        Text {
            Layout.fillWidth: true
            text: Nightlight.active
                ? "Gammastep " + Nightlight.temperature + "K"
                : "Gammastep"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Nightlight.active ? Theme.text : Theme.overlay0
        }

        ToggleSwitch {
            checked: Nightlight.active
            onToggled: Nightlight.toggle()
        }
    }
}
