import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root
  screen: Quickshell.screens[0]

  property string searchText: ""
  property var filtered: []
  property int selectedIndex: 0

  anchors {
    top: true
  }

  margins.top: 80
  implicitWidth: 400
  implicitHeight: 300
  color: "transparent"

  WlrLayershell.namespace: "quickshell:menu"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusiveZone: 0
  visible: false

  property var allApps: []

  Process {
    id: listApps
    command: ["bash", "-c", "find /usr/share/applications /usr/local/share/applications ~/.local/share/applications -name '*.desktop' -exec grep -l '^Exec=' {} + 2>/dev/null | while read f; do name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/%[fFuU]//g' | xargs); [ -n \"$name\" ] && echo \"$name|$exec\"; done | sort -u | head -100"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const parts = data.split("|")
        if (parts.length >= 2 && parts[0].trim() && parts[1].trim()) {
          root.allApps.push({ name: parts[0].trim(), exec: parts[1].trim() })
        }
      }
    }
    onExited: root.applyFilter()
  }

  Process {
    id: launchProc
    command: ["bash", "-c", ""]
    running: false
  }

  function applyFilter() {
    const q = searchText.toLowerCase()
    filtered = allApps.filter(a => a.name.toLowerCase().includes(q))
    selectedIndex = 0
  }

  function launchSelected() {
    if (filtered.length === 0) return
    const app = filtered[selectedIndex]
    if (!app.exec) return
    launchProc.command = ["bash", "-c", app.exec + " &"]
    launchProc.running = false
    launchProc.running = true
    root.visible = false
    root.searchText = ""
  }

  Component.onCompleted: listApps.running = true

  IpcHandler {
    target: "menu"
    function toggle(): void {
      root.visible = !root.visible
      if (root.visible) {
        searchText = ""
        allApps = []
        listApps.running = true
        focusTimer.restart()
      }
    }
  }

  Timer {
    id: focusTimer
    interval: 50
    onTriggered: input.forceActiveFocus()
  }

  Rectangle {
    anchors.fill: parent
    color: colorBase
    radius: 10

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 6

      Rectangle {
        Layout.fillWidth: true
        height: 32
        radius: 6
        color: colorSurface0

        TextInput {
          id: input
          anchors.fill: parent
          anchors.margins: 8
          color: colorText
          selectionColor: colorBlue
          font { family: themeFont; pixelSize: 14; weight: 600 }
          clip: true
          focus: true

          onTextChanged: {
            root.searchText = text
            root.applyFilter()
          }

          Keys.onDownPressed: {
            root.selectedIndex = Math.min(root.selectedIndex + 1, root.filtered.length - 1)
          }
          Keys.onUpPressed: {
            root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
          }
          Keys.onReturnPressed: root.launchSelected()
          Keys.onEscapePressed: {
            root.visible = false
            root.searchText = ""
          }

          Text {
            visible: input.text === "" && !input.activeFocus
            text: "Search apps..."
            color: colorOverlay0
            font: input.font
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: colorSurface1 }

      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.filtered
        currentIndex: root.selectedIndex

        delegate: Rectangle {
          required property var modelData
          required property int index

          height: 32
          radius: 4
          color: index === root.selectedIndex ? colorSurface1 : "transparent"

          Text {
            anchors.fill: parent
            anchors.margins: 6
            text: modelData.name
            color: colorText
            font { family: themeFont; pixelSize: 13; weight: 600 }
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onDoubleClicked: root.launchSelected()
            onContainsMouseChanged: {
              if (containsMouse) root.selectedIndex = index
            }
          }
        }
      }
    }
  }
}
