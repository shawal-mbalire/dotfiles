import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../../domain"
import "../../infra"
import "../../adapters"

// Polkit authentication prompt. Exists only while a request is pending; a
// full-screen overlay dims the session and grabs the keyboard.
LazyLoader {
    id: loader
    active: Polkit.active

    PanelWindow {
        id: prompt

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)

            MouseArea {
                anchors.fill: parent
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            implicitWidth: 380
            implicitHeight: content.implicitHeight + 28
            radius: Theme.radius
            color: Theme.tint(Theme.mantle, 0.98)
            border.width: 1
            border.color: Theme.tint(WallpaperColors.accent, 0.6)

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                MenuTitle {
                    title: "Authentication Required"
                    subtitle: Polkit.message
                }

                // Identity chooser (only shown when more than one is available).
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: Polkit.identities.length > 1

                    Repeater {
                        model: Polkit.identities
                        MenuButton {
                            required property var modelData
                            label: modelData.displayName
                            onClicked: if (Polkit.flow) Polkit.flow.selectedIdentity = modelData
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Theme.radius - 2
                    color: Theme.tint(Theme.surface0, 0.7)
                    border.width: 1
                    border.color: Polkit.supplementaryIsError
                        ? Theme.tint(Theme.red, 0.7)
                        : Theme.tint(Theme.surface1, 0.6)

                    TextInput {
                        id: input
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: Polkit.responseVisible ? TextInput.Normal : TextInput.Password
                        clip: true
                        selectByMouse: true
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        onAccepted: prompt.submit()
                        Keys.onEscapePressed: Polkit.cancel()
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        visible: input.text === ""
                        text: Polkit.inputPrompt
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.overlay0
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Polkit.supplementary !== ""
                    text: Polkit.supplementary
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Polkit.supplementaryIsError ? Theme.red : Theme.subtext0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    MenuButton {
                        label: "Cancel"
                        onClicked: Polkit.cancel()
                    }

                    Rectangle {
                        implicitWidth: authLabel.implicitWidth + 20
                        implicitHeight: 26
                        radius: Theme.radius - 3
                        color: Theme.tint(WallpaperColors.accent, 0.85)

                        Text {
                            id: authLabel
                            anchors.centerIn: parent
                            text: "Authenticate"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.crust
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: prompt.submit()
                        }
                    }
                }
            }
        }

        function submit() {
            Polkit.submit(input.text);
        }

        Connections {
            target: Polkit.flow
            function onAuthenticationFailed() {
                input.text = "";
                input.forceActiveFocus();
            }
        }

        Component.onCompleted: input.forceActiveFocus()
    }
}
