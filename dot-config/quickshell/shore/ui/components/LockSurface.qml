import QtQuick
import QtQuick.Layouts
import "../../domain"

// Lock surface (one per monitor). Shares state via the LockContext so all
// monitors stay in sync.
Rectangle {
    id: root

    required property LockContext context

    color: Theme.tint(Theme.crust, 0.98)

    // ── Clock ─────────────────────────────────────────────────────────────
    property date now: new Date()

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            font.family: Theme.fontFamily
            font.pixelSize: 84
            font.bold: true
            color: Theme.text
            renderType: Text.NativeRendering
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: Theme.subtext0
        }

        Item { implicitHeight: 24 }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 360
            implicitHeight: 40
            radius: Theme.radius
            color: Theme.tint(Theme.surface0, 0.8)
            border.width: 1
            border.color: root.context.showFailure
                ? Theme.tint(Theme.red, 0.8)
                : Theme.tint(Theme.surface1, 0.6)

            TextInput {
                id: input
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                enabled: !root.context.unlockInProgress
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
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
                    font.pixelSize: Theme.fontSize
                    color: Theme.overlay0
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.context.showFailure
            text: "Incorrect password"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.red
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
