import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

LazyLoader {
    id: loader
    active: UiState.controlCenterOpen

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusiveZone: 0

        // Close on any click outside the panel
        MouseArea {
            anchors.fill: parent
            onClicked: UiState.closePanels()
        }

        // Close on Escape
        Keys.onEscapePressed: UiState.closePanels()

        Rectangle {
            id: panel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Theme.barHeight + 4
            anchors.rightMargin: 8
            implicitWidth: 360
            implicitHeight: Math.min(content.implicitHeight + 24, screen ? screen.height - Theme.barHeight - 20 : 700)

            readonly property var sink: Audio.defaultSink
            readonly property var audio: Audio.defaultSinkAudio

            radius: Theme.radius
            color: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.85)
            border.width: 0

            // Left vertical bar
            Rectangle {
                width: 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Theme.radius
                anchors.bottomMargin: Theme.radius
                color: Theme.tint(Theme.surface1, 0.85)
            }

            // Right vertical bar
            Rectangle {
                width: 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.topMargin: Theme.radius
                anchors.bottomMargin: Theme.radius
                color: Theme.tint(Theme.surface1, 0.85)
            }

            // Prevent clicks inside the panel from propagating to the backdrop
            MouseArea {
                anchors.fill: parent
            }

            property string pendingAction: ""

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 10

                // ── Connectivity ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Network.wiredConnected ? Theme.iconWired : Theme.iconNetwork
                        label: "Wi-Fi"
                        active: Network.wifiEnabled
                        accent: Theme.lavender
                        onToggled: UiState.toggleMenu("connectivity")
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Theme.iconBluetooth
                        label: "Bluetooth"
                        active: Bluetooth.enabled
                        accent: WallpaperColors.accent
                        onToggled: UiState.toggleMenu("connectivity")
                    }
                }


                // ── Display ─────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

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
                        visible: Compositor.monitorCount > 1
                        icon: Theme.iconDisplay
                        label: "Displays"
                        active: false
                        accent: Theme.teal
                        onToggled: UiState.toggleMenu("display")
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


                // ── Media ───────────────────────────────────────────────
                SliderRow {
                    Layout.fillWidth: true
                    icon: panel.audio && panel.audio.muted ? Theme.iconVolumeMuted : Theme.iconVolume
                    value: panel.audio ? Math.min(panel.audio.volume, 1.0) : 0
                    label: panel.audio ? Math.round(panel.audio.volume * 100) + "%" : "--"
                    accent: Theme.sapphire
                    onMoved: value => {
                        if (panel.audio) {
                            panel.audio.muted = false;
                            Audio.setVolume(panel.sink, value);
                        }
                    }
                }

                MediaPlayer {
                    Layout.fillWidth: true
                }


                // ── System ───────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radius
                        color: Theme.tint(Theme.surface0, 0.85)
                        border.width: 1
                        border.color: Theme.tint(Theme.surface1, 0.85)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: Theme.iconBattery
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                                color: Battery.charging ? Theme.teal
                                     : Battery.percent <= Constants.batteryCritical ? Theme.red
                                     : Battery.percent <= Constants.batteryLow ? Theme.yellow
                                     : Theme.green
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: Battery.present
                                text: Battery.percent + "%" + (Battery.charging ? " charging" : "")
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Theme.text
                            }

                            Text {
                                visible: !Battery.present
                                text: "No battery"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Theme.overlay0
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radius
                        color: Theme.tint(Theme.surface0, 0.85)
                        border.width: 1
                        border.color: Theme.tint(Theme.surface1, 0.85)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: Theme.iconPower
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                                color: Battery.profileLabel === "performance" ? Theme.red
                                     : Battery.profileLabel === "power-saver" ? Theme.blue
                                     : Theme.green
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Battery.profileLabel
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Theme.text
                            }
                        }
                    }
                }

                ToggleTile {
                    Layout.fillWidth: true
                    icon: Notifications.dnd ? Theme.iconBellDnd : Theme.iconBell
                    label: "Do Not Disturb"
                    active: Notifications.dnd
                    accent: Theme.mauve
                    onToggled: Notifications.toggleDnd()
                }

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
                Repeater {
                    model: [
                        { "icon": "\uF023", "label": "Lock",     "action": "lock",     "danger": false },
                        { "icon": "\uF2F5", "label": "Logout",   "action": "logout",   "danger": true  },
                        { "icon": "\uF021", "label": "Reboot",   "action": "reboot",   "danger": true  },
                        { "icon": "\u23FB", "label": "Shutdown", "action": "poweroff", "danger": true  },
                        { "icon": "\uF186", "label": "Suspend",  "action": "suspend",  "danger": true  }
                    ]

                    Rectangle {
                        id: powerRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Theme.radius
                        color: contentRow.confirming
                            ? Theme.tint(Theme.red, 0.3)
                            : powerRowHover.pressed ? Theme.tint(Theme.surface0, 0.6)
                            : powerRowHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
                            : Theme.tint(Theme.surface0, 0.5)
                        border.width: 1
                        border.color: contentRow.confirming
                            ? Theme.tint(Theme.red, 0.6)
                            : Theme.tint(Theme.surface1, 0.85)

                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            id: contentRow
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 8

                            readonly property bool confirming: powerRow.modelData.action === panel.pendingAction

                            Text {
                                text: powerRow.modelData.icon
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 14
                                color: contentRow.confirming ? Theme.red : Theme.subtext1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: contentRow.confirming
                                    ? "Confirm " + powerRow.modelData.label + "?"
                                    : powerRow.modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: contentRow.confirming ? Theme.red : Theme.text
                            }

                            Text {
                                visible: !contentRow.confirming && powerRow.modelData.danger
                                text: "\uF054"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 10
                                color: Theme.overlay0
                            }
                        }

                        MouseArea {
                            id: powerRowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const action = powerRow.modelData.action;
                                if (panel.pendingAction === action) {
                                    panel.pendingAction = "";
                                    if (action === "lock") UiState.lock();
                                    else if (action === "logout") Compositor.logout();
                                    else if (action === "reboot") Session.reboot();
                                    else if (action === "poweroff") Session.poweroff();
                                    else if (action === "suspend") Session.suspend();
                                } else if (powerRow.modelData.danger) {
                                    panel.pendingAction = action;
                                } else {
                                    UiState.lock();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
