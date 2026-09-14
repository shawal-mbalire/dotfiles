import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../domain"
import "../adapters"
import "../infra"

// Login surface: blurred current wallpaper, large clock, username, password
// box and a session picker. Visually identical to shore's lock screen, so the
// login screen and the session lock feel like the same surface.
Rectangle {
    id: root

    required property var context

    color: Theme.base

    property date now: new Date()

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    // ── Blurred wallpaper background ──────────────────────────────────────
    Image {
        anchors.fill: parent
        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 64
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    // ── Clock + prompt ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            font.family: Theme.fontFamily
            font.pixelSize: 150
            font.bold: true
            color: Theme.text
            renderType: Text.NativeRendering
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
            font.family: Theme.fontFamily
            font.pixelSize: 22
            color: Theme.subtext0
        }

        Item { implicitHeight: 30 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                text: Config.defaultUser
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
                color: Theme.subtext1
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 420
            implicitHeight: 46
            radius: Theme.radius
            color: Theme.tint(Theme.surface0, 0.7)
            border.width: 1
            border.color: root.context.showFailure ? Theme.red : WallpaperColors.accent

            TextInput {
                id: input
                anchors {
                    fill: parent
                    leftMargin: 14
                    rightMargin: 14
                }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: root.context.echoResponse ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2
                clip: true

                onTextChanged: if (text !== root.context.currentText) root.context.currentText = text
                onAccepted: root.context.submit()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (input.text !== root.context.currentText)
                            input.text = root.context.currentText;
                    }
                    function onAwaitingResponseChanged() {
                        if (root.context.awaitingResponse)
                            input.forceActiveFocus();
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    visible: input.text === ""
                    text: root.context.awaitingResponse && root.context.message !== ""
                        ? root.context.message
                        : "Password"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    color: Theme.overlay0
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.context.showFailure
            text: root.context.message !== "" ? root.context.message : "Authentication failed"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.red
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.context.showFailure && !root.context.awaitingResponse
                && root.context.message !== ""
            text: root.context.message
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.subtext0
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.context.showFailure && root.context.message === ""
            text: "Touch the fingerprint reader or type your password"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.overlay0
        }

        Item { implicitHeight: 10 }

        // ── Session picker (one-off override for the current login) ───────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            visible: Sessions.entries.length > 1

            Repeater {
                model: Sessions.entries

                Rectangle {
                    required property var modelData
                    required property int index

                    implicitWidth: label.implicitWidth + 22
                    implicitHeight: 28
                    radius: Theme.radius
                    color: index === Sessions.selected
                        ? Theme.tint(WallpaperColors.accent, 0.35)
                        : Theme.tint(Theme.surface0, 0.5)
                    border.width: 1
                    border.color: index === Sessions.selected
                        ? WallpaperColors.accent
                        : Theme.tint(Theme.overlay0, 0.5)

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.name
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: index === Sessions.selected ? Theme.text : Theme.subtext0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Sessions.selected = index
                    }
                }
            }
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
