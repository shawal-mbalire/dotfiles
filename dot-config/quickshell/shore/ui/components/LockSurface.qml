import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."
import "../../domain"
import "../../adapters"

// Lock surface (one per monitor): blurred wallpaper, large clock, password box.
// Shares state via the LockContext so all monitors stay in sync.
Rectangle {
    id: root

    required property LockContext context

    color: "black"

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
        color: Qt.rgba(0, 0, 0, 0.4)
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
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                enabled: !root.context.unlockInProgress
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2
                clip: true

                onTextChanged: root.context.currentText = text
                onAccepted: root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (input.text !== root.context.currentText)
                            input.text = root.context.currentText;
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    visible: input.text === ""
                    text: "Password"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    color: Theme.overlay0
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.context.showFailure
            text: "Incorrect password"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.red
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
