import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."
import "../../domain"
import "../../adapters"

// Lock surface (one per monitor): blurred wallpaper, large clock, password box.
// Shares state via the Auth adapter so all monitors stay in sync.
Rectangle {
    id: root

    required property var context

    color: "black"

    property date now: new Date()
    property bool idle: true

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    // Return to idle after 5 seconds of no interaction.
    Timer {
        id: idleTimer
        interval: 600000
        onTriggered: root.idle = true
    }

    // ── Input detection (wake from idle) ──────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: root.wake()
        onClicked: root.wake()
        onPressed: root.wake()
        cursorShape: Qt.ArrowCursor
    }

    function wake() {
        if (!root.idle) {
            idleTimer.restart();
            return;
        }
        root.idle = false;
        idleTimer.restart();
        root.context.start();
        input.forceActiveFocus();
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
            blurMax: 32
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

        // Interactive area: password field + messages (hidden when idle).
        Item {
            id: interactiveArea
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420
            Layout.preferredHeight: 120
            opacity: root.idle ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: passwordBox
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: 420
                implicitHeight: 46
                radius: Theme.radius
                color: Theme.tint(Theme.surface0, 0.85)
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
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    clip: true

                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.submit()

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
                anchors.top: passwordBox.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.context.showFailure
                text: "Incorrect password"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.red
            }

            Text {
                anchors.top: passwordBox.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.context.showFailure && root.context.message !== ""
                text: root.context.message
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.subtext0
            }
        }
    }

    Component.onCompleted: root.context.start()
}
