import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../../domain"
import "../../adapters"

// System menu: brightness, media, battery, notifications, power actions.
BaseMenu {
    id: root

    property string pendingAction: ""

    MenuTitle {
        title: "System"
        subtitle: Battery.present
            ? Battery.percent + "%" + (Battery.charging ? " charging" : "")
            : "No battery"
    }

    // ── Brightness ─────────────────────────────────────────────────
    SliderRow {
        Layout.fillWidth: true
        icon: Theme.iconBrightness
        value: Backlight.percent / 100
        label: Backlight.percent + "%"
        accent: WallpaperColors.accent
        onMoved: value => Backlight.setPercent(value * 100)
    }

    // ── Power profile ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: Battery.profiles

            Rectangle {
                id: profBtn
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.menuCompactRowHeight
                radius: Theme.radius
                readonly property bool current: Battery.profile === modelData.value
                readonly property color accent: modelData.label === "Performance" ? Theme.red
                    : modelData.label === "Power Saver" ? Theme.blue
                    : Theme.green

                color: current ? Qt.rgba(accent.r, accent.g, accent.b, 0.8)
                     : profHover.pressed ? Theme.tint(Theme.surface0, 0.6)
                     : profHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
                     : Theme.tint(Theme.surface0, 0.5)
                border.width: 1
                border.color: Theme.tint(Theme.surface1, 0.85)

                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: profBtn.modelData.label === "Performance" ? "Perf"
                        : profBtn.modelData.label === "Power Saver" ? "Saver"
                        : profBtn.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: profBtn.current ? Theme.crust : Theme.text
                }

                MouseArea {
                    id: profHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Battery.setProfile(profBtn.modelData.value)
                }
            }
        }
    }

    // ── Media ───────────────────────────────────────────────────────
    MediaPlayer {
        Layout.fillWidth: true
    }

    // ── Battery ─────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.menuRowHeight
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

    // ── Notifications ───────────────────────────────────────────────
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
            color: WallpaperColors.accent

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
        implicitHeight: Math.min(contentHeight, 200)
        model: Notifications.model
        spacing: 6
        clip: true
        cacheSize: 5
        boundsBehavior: Flickable.StopAtBounds

        delegate: NotificationItem {
            required property var modelData
            width: ListView.view.width
            notification: modelData
        }
    }

    // ── Power ───────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { "icon": "\uF023", "action": "lock",     "danger": false },
                { "icon": "\uF2F5", "action": "logout",   "danger": true  },
                { "icon": "\uF021", "action": "reboot",   "danger": true  },
                { "icon": "\u23FB", "action": "poweroff", "danger": true  },
                { "icon": "\uF186", "action": "suspend",  "danger": true  }
            ]

            Rectangle {
                id: pwrBtn
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.menuCompactRowHeight
                radius: Theme.radius
                readonly property bool confirming: root.pendingAction === modelData.action
                color: confirming ? Theme.tint(Theme.red, 0.3)
                     : pwrHover.pressed ? Theme.tint(Theme.surface0, 0.6)
                     : pwrHover.containsMouse ? Theme.tint(Theme.surface0, 0.85)
                     : Theme.tint(Theme.surface0, 0.5)
                border.width: 1
                border.color: confirming ? Theme.tint(Theme.red, 0.6) : Theme.tint(Theme.surface1, 0.85)

                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: pwrBtn.modelData.icon
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 14
                    color: pwrBtn.confirming ? Theme.red : Theme.subtext1
                }

                MouseArea {
                    id: pwrHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const a = pwrBtn.modelData.action;
                        if (root.pendingAction === a) {
                            root.pendingAction = "";
                            if (a === "lock") UiState.lock();
                            else if (a === "logout") Compositor.logout();
                            else if (a === "reboot") Session.reboot();
                            else if (a === "poweroff") Session.poweroff();
                            else if (a === "suspend") Session.suspend();
                        } else if (pwrBtn.modelData.danger) {
                            root.pendingAction = a;
                        } else {
                            UiState.lock();
                        }
                    }
                }
            }
        }
    }
}
