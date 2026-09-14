import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../../domain"
import "../../infra"
import "../../adapters"

// Launcher: applications and clipboard history in one searchable overlay.
// Opens centred, keyboard-exclusive; Esc closes, Up/Down navigate, Enter runs.
LazyLoader {
    id: loader
    active: UiState.launcherOpen

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

        readonly property bool clipboard: UiState.launcherMode === "clipboard"
        readonly property var appResults: Launcher.search(query.text)
        readonly property var clipResults: {
            const q = query.text.trim().toLowerCase();
            const items = Clipboard.items;
            const filtered = q === "" ? items
                : items.filter(l => Formatters.clipLabel(l).toLowerCase().indexOf(q) !== -1);
            return filtered.slice(0, 100);
        }
        readonly property int count: clipboard ? clipResults.length : appResults.length

        function activate() {
            if (count === 0) return;
            if (clipboard) Clipboard.copy(clipResults[list.currentIndex]);
            else Launcher.launch(appResults[list.currentIndex]);
            UiState.closeLauncher();
        }

        function move(delta) {
            if (count === 0) return;
            list.currentIndex = Math.max(0, Math.min(count - 1, list.currentIndex + delta));
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            MouseArea {
                anchors.fill: parent
                onClicked: UiState.closeLauncher()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.16)
            implicitWidth: 560
            implicitHeight: content.implicitHeight + 24
            radius: Theme.radius
            color: Theme.tint(Theme.mantle, 0.98)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.7)

            MouseArea {
                anchors.fill: parent
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MenuButton {
                        label: "Apps"
                        onClicked: {
                            UiState.launcherMode = "apps";
                            query.forceActiveFocus();
                        }
                    }

                    MenuButton {
                        label: "Clipboard"
                        onClicked: {
                            UiState.launcherMode = "clipboard";
                            Clipboard.refresh();
                            query.forceActiveFocus();
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ navigate · Enter run · Esc close"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.overlay0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Theme.radius - 2
                    color: Theme.tint(Theme.surface0, 0.7)
                    border.width: 1
                    border.color: Theme.tint(Theme.surface1, 0.7)

                    TextInput {
                        id: query
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        clip: true
                        onTextChanged: list.currentIndex = prompt.count > 0 ? 0 : -1
                        onAccepted: prompt.activate()
                        Keys.onDownPressed: prompt.move(1)
                        Keys.onUpPressed: prompt.move(-1)
                        Keys.onEscapePressed: UiState.closeLauncher()
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        visible: query.text === ""
                        text: prompt.clipboard ? "Search clipboard…" : "Search applications…"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        color: Theme.overlay0
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 380)
                    model: prompt.clipboard ? prompt.clipResults : prompt.appResults
                    spacing: 3
                    clip: true
                    currentIndex: count > 0 ? 0 : -1
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        implicitHeight: prompt.clipboard ? 32 : 44
                        radius: Theme.radius - 2
                        color: row.index === list.currentIndex
                            ? Theme.tint(WallpaperColors.accent, 0.75)
                            : Theme.tint(Theme.surface0, 0.35)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                list.currentIndex = row.index;
                                prompt.activate();
                            }
                        }

                        // Clipboard entry
                        Text {
                            visible: prompt.clipboard
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10
                                rightMargin: 10
                            }
                            text: prompt.clipboard ? Formatters.clipLabel(row.modelData) : ""
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: row.index === list.currentIndex ? Theme.crust : Theme.text
                        }

                        // Application entry
                        RowLayout {
                            visible: !prompt.clipboard
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10
                                rightMargin: 10
                            }
                            spacing: 10

                            Image {
                                source: row.modelData && !prompt.clipboard
                                    ? Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                    : ""
                                sourceSize.width: 24
                                sourceSize.height: 24
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: prompt.clipboard ? "" : (row.modelData ? row.modelData.name : "")
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    color: row.index === list.currentIndex ? Theme.crust : Theme.text
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: prompt.clipboard ? "" : (row.modelData ? (row.modelData.comment || row.modelData.genericName || "") : "")
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: row.index === list.currentIndex ? Theme.tint(Theme.crust, 0.8) : Theme.subtext0
                                }
                            }
                        }
                    }
                }
            }
        }

        Component.onCompleted: query.forceActiveFocus()
    }
}
