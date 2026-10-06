// Quickshell references:
//   DesktopEntries    https://quickshell.org/docs/v0.3.0/types/Quickshell/DesktopEntries
//   DesktopEntry      https://quickshell.org/docs/v0.3.0/types/Quickshell/DesktopEntry
//   IconImage         https://quickshell.org/docs/v0.3.0/types/Quickshell.Widgets/IconImage
//   HyprlandFocusGrab https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandFocusGrab
import "../Shared"
import "../Domain/Ports"
import "../Domain/Constants"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Overlay {
  id: root
  required property var modelData
  required property LaunchPort launchPort

  title: "App Launcher"
  shellNamespace: "quickshell:app-launcher"
  implicitWidth: 460
  implicitHeight: 440
  screen: modelData

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property string searchText: ""
  property int selectedIndex: 0
  readonly property var filtered: Applications.filter(launchPort.applications, searchText)

  // Click anywhere outside the launcher to dismiss it.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: root.closeRequested()
  }

  function launchSelected() {
    if (filtered.length === 0) return
    const idx = Math.max(0, Math.min(selectedIndex, filtered.length - 1))
    root.launchPort.launch(filtered[idx].id)
    root.searchText = ""
    root.closeRequested()
  }

  onVisibleChanged: {
    if (!visible) return
    input.text = ""
    searchText = ""
    selectedIndex = 0
    focusTimer.restart()
  }

  Timer {
    id: focusTimer
    interval: 50
    onTriggered: input.forceActiveFocus()
  }

  readonly property string statusText: {
    if (launchPort.applications.length === 0) return "No applications found"
    return "No matches"
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.paddingLg
    spacing: Theme.spacingLg

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 36
      radius: Theme.radiusSm
      color: Theme.surface0

      TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: Theme.paddingSm
        color: Theme.text
        selectionColor: Theme.blue
        font { family: Theme.font; pixelSize: 14; weight: 600 }
        clip: true
        focus: true

        onTextChanged: {
          root.searchText = text
          root.selectedIndex = 0
        }

        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filtered.length - 1))
        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        Keys.onReturnPressed: root.launchSelected()
        Keys.onEnterPressed: root.launchSelected()
        Keys.onEscapePressed: root.closeRequested()

        Text {
          visible: input.text === "" && !input.activeFocus
          text: "Search apps..."
          color: Theme.overlay0
          font: input.font
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.surface1 }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      visible: root.filtered.length > 0
      model: root.filtered
      currentIndex: root.selectedIndex

      delegate: Rectangle {
        required property var modelData
        required property int index
        height: 40
        radius: Theme.radiusSm
        color: index === root.selectedIndex ? Theme.surface1 : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.margins: Theme.paddingSm
          spacing: Theme.paddingSm

          Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            clip: true

            IconImage {
              anchors.fill: parent
              source: modelData.icon
              visible: modelData.icon !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: modelData.icon === ""
              text: String.fromCodePoint(0xF0494)
              color: Theme.overlay0
              font { family: Theme.nerdFont; pixelSize: 16; weight: Theme.fontWeight }
            }
          }

          ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
              text: modelData.name
              color: Theme.text
              font { family: Theme.font; pixelSize: 13; weight: 600 }
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: modelData.genericName
              visible: text !== ""
              color: Theme.overlay0
              font { family: Theme.font; pixelSize: 10; weight: 600 }
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onContainsMouseChanged: { if (containsMouse) root.selectedIndex = index }
          onDoubleClicked: root.launchSelected()
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.filtered.length === 0

      Text {
        anchors.centerIn: parent
        text: root.statusText
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 12; weight: 600 }
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
