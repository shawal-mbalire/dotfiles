import "../Shared"
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
    onTriggered: if (!checkProc.running) checkProc.running = true
  }

  Component.onCompleted: checkProc.running = true

  function toggle() {
    if (root.active) {
      Quickshell.execDetached(["killall", "gammastep"])
      root.active = false
    } else {
      Quickshell.execDetached(["gammastep", "-m", "wayland", "-O", "16000"])
      root.active = true
    }
  }

  Item {
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
      id: icon
      text: String.fromCodePoint(0xF0594)
      color: root.active ? Theme.peach : Theme.overlay0
      font {
        family: Theme.nerdFont
        pixelSize: Theme.fontSize
        weight: Theme.fontWeight
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggle()
    }
  }
}
