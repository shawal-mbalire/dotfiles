import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property bool active: false

  Process {
    id: checkProc
    command: ["pgrep", "gammastep"]
    running: false
    onExited: exitCode => {
      root.active = exitCode === 0
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: checkProc.running = true
  }

  Component.onCompleted: checkProc.running = true

  function toggle() {
    if (root.active) {
      Quickshell.execDetached(["killall", "gammastep"])
      root.active = false
    } else {
      Quickshell.execDetached(["gammastep", "-m", "wayland", "-t", "6500:16000"])
      root.active = true
    }
  }

  Item {
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
      id: icon
      text: "\uf185"
      color: root.active ? colorYellow : colorOverlay0
      font {
        family: themeNerdFont
        pixelSize: themeFontSize
        weight: themeFontWeight
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.toggle()
    }
  }
}
