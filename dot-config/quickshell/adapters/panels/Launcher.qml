import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../../domain"
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
        readonly property var appResults: Launcher.results
        property string _clipQuery: ""
        property var clipResults: _computeClipResults("")

        function _fuzzyScore(s, q) {
            if (q === "") return 1;
            let si = 0, qi = 0, score = 0, consecutive = 0;
            while (si < s.length && qi < q.length) {
                if (s[si] === q[qi]) {
                    qi++;
                    consecutive++;
                    score += consecutive * 10;
                } else {
                    consecutive = 0;
                }
                si++;
            }
            return qi === q.length ? score : 0;
        }

        function _computeClipResults(q) {
            const items = Clipboard.items;
            if (q === "") return items.slice(0, 100);

            return items
                .map(l => {
                    const label = Formatters.clipLabel(l).toLowerCase();
                    const pos = label.indexOf(q);
                    let score = 0;
                    if (pos === 0) score = 5000 + (q.length / label.length) * 1000;
                    else if (pos !== -1) score = 3000 - pos;
                    else score = prompt._fuzzyScore(label, q);
                    return { line: l, score: score };
                })
                .filter(r => r.score > 0)
                .sort((a, b) => b.score - a.score)
                .slice(0, 100)
                .map(r => r.line);
        }

        Timer {
            id: clipDebounce
            interval: 50
            onTriggered: {
                prompt._clipQuery = query.text.trim().toLowerCase();
                prompt.clipResults = prompt._computeClipResults(prompt._clipQuery);
            }
        }

        Connections {
            target: Clipboard
            function onItemsChanged() {
                prompt.clipResults = prompt._computeClipResults(prompt._clipQuery);
            }
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
            color: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.85)
            border.width: 1
            border.color: Theme.tint(Theme.surface1, 0.85)

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
                    color: Theme.tint(Theme.surface0, 0.85)
                    border.width: 1
                    border.color: Theme.tint(Theme.surface1, 0.85)

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
                        onTextChanged: {
                            if (prompt.clipboard) clipDebounce.restart();
                            else Launcher.search(query.text);
                            list.currentIndex = prompt.count > 0 ? 0 : -1;
                        }
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
                    cacheSize: 5
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
                            ? Theme.tint(WallpaperColors.accent, 0.85)
                            : Theme.tint(Theme.surface0, 0.85)

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
                                    color: row.index === list.currentIndex ? Theme.tint(Theme.crust, 0.85) : Theme.subtext0
                                }
                            }
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            query.forceActiveFocus();
            if (!clipboard) Launcher.search("");
        }
    }
}
