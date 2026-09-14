import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "../components"
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

LazyLoader {
    id: loader
    active: UiState.controlCenterOpen

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.barHeight + 4
            right: 8
        }
        implicitWidth: 360
        implicitHeight: Math.min(panel.implicitHeight, screen ? screen.height - Theme.barHeight - 20 : 700)
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            id: panel

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var audio: sink ? sink.audio : null

            anchors.fill: parent
            implicitHeight: content.implicitHeight + 24
            radius: Theme.radius
            color: Theme.tint(Theme.mantle, 0.97)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.6)

            PwObjectTracker {
                objects: [ panel.sink ]
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 10

                // ── Quick toggles ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Network.wiredConnected ? Theme.iconWired : Theme.iconNetwork
                        label: "Wi-Fi"
                        active: Network.wifiEnabled
                        accent: Theme.lavender
                        onToggled: UiState.toggleMenu("wifi")
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Theme.iconBluetooth
                        label: "Bluetooth"
                        active: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                        accent: WallpaperColors.accent
                        onToggled: UiState.toggleMenu("bluetooth")
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Theme.iconNight
                        label: "Night"
                        active: Nightlight.active
                        accent: Theme.pink
                        onToggled: Nightlight.toggle()
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Notifications.dnd ? Theme.iconBellDnd : Theme.iconBell
                        label: "DND"
                        active: Notifications.dnd
                        accent: Theme.mauve
                        onToggled: Notifications.toggleDnd()
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        visible: Hyprland.monitors.values.length > 1
                        icon: "\uF108"
                        label: "Displays"
                        active: false
                        accent: Theme.teal
                        onToggled: UiState.toggleMenu("display")
                    }
                }

                // ── Sliders ───────────────────────────────────────────────
                SliderRow {
                    Layout.fillWidth: true
                    icon: panel.audio && panel.audio.muted ? Theme.iconVolumeMuted : Theme.iconVolume
                    value: panel.audio ? panel.audio.volume : 0
                    label: panel.audio ? Math.round(panel.audio.volume * 100) + "%" : "--"
                    accent: Theme.sapphire
                    onMoved: value => {
                        if (panel.audio) {
                            panel.audio.muted = false;
                            panel.audio.volume = value;
                        }
                    }
                }

                SliderRow {
                    Layout.fillWidth: true
                    icon: Theme.iconBrightness
                    value: Backlight.percent / 100
                    label: Backlight.percent + "%"
                    accent: Theme.yellow
                    onMoved: value => Backlight.setPercent(value * 100)
                }

                // ── Media ─────────────────────────────────────────────────
                MediaPlayer {
                    Layout.fillWidth: true
                }

                // ── Notifications ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        visible: Notifications.count > 0
                        text: "clear all"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.mauve

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.dismissAll()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Notifications.count === 0
                    text: "No notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.overlay0
                }

                ListView {
                    Layout.fillWidth: true
                    visible: Notifications.count > 0
                    implicitHeight: Math.min(contentHeight, 320)
                    model: Notifications.model
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: NotificationItem {
                        required property var modelData
                        width: ListView.view.width
                        notification: modelData
                    }
                }

                // ── Power ─────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { "icon": "\uF023", "cmd": ["hyprlock"] },
                            { "icon": "\uF2F5", "cmd": ["hyprctl", "dispatch", "exit"] },
                            { "icon": "\uF021", "cmd": ["systemctl", "reboot"] },
                            { "icon": "\u23FB", "cmd": ["systemctl", "poweroff"] },
                            { "icon": "\uF186", "cmd": ["systemctl", "suspend"] }
                        ]

                        Rectangle {
                            id: powerButton
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Theme.radius
                            color: Theme.tint(Theme.surface0, 0.5)
                            border.width: 1
                            border.color: Theme.tint(Theme.surface1, 0.5)

                            Text {
                                anchors.centerIn: parent
                                text: powerButton.modelData.icon
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 15
                                color: Theme.subtext1
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(powerButton.modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
