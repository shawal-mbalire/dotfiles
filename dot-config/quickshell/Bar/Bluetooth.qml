import "../Shared"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property bool bluetoothEnabled: false
  property string deviceName: ""

  readonly property bool connected: bluetoothEnabled && deviceName !== ""

  readonly property string icon: {
    if (!bluetoothEnabled) return String.fromCodePoint(0xF00B2)
    if (connected) return String.fromCodePoint(0xF00B1)
    return String.fromCodePoint(0xF00AF)
  }

  readonly property string status: {
    if (!bluetoothEnabled) return "off"
    if (connected) return deviceName
    return "on"
  }

  Process {
    id: stateProc
    command: ["bash", "-c", "p=off; bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && p=on; n=''; if [ \"$p\" = on ]; then i=0; for d in $(bluetoothctl devices 2>/dev/null | cut -d' ' -f2); do [ $i -ge 8 ] && break; i=$((i+1)); if bluetoothctl info \"$d\" 2>/dev/null | grep -q 'Connected: yes'; then n=$(bluetoothctl info \"$d\" 2>/dev/null | sed -n 's/^[[:space:]]*Name: //p'); break; fi; done; fi; echo \"$p|$n\""]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const parts = data.split("|")
        root.bluetoothEnabled = parts[0] === "on"
        root.deviceName = parts.length > 1 ? parts[1].trim() : ""
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: if (!stateProc.running) stateProc.running = true
  }

  Component.onCompleted: stateProc.running = true

  function toggle() {
    root.bluetoothEnabled = !root.bluetoothEnabled
    if (!root.bluetoothEnabled) root.deviceName = ""
    Quickshell.execDetached(["bluetoothctl", "power", root.bluetoothEnabled ? "on" : "off"])
    stateTimer.restart()
  }

  Timer {
    id: stateTimer
    interval: 600
    onTriggered: stateProc.running = true
  }

  Item {
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
      id: row
      spacing: root.spacing

      Text {
        text: root.icon
        color: root.bluetoothEnabled ? Theme.blue : Theme.overlay0
        font {
          family: Theme.nerdFont
          pixelSize: Theme.fontSize
          weight: Theme.fontWeight
        }
      }

      Text {
        text: root.status
        color: root.bluetoothEnabled ? Theme.blue : Theme.overlay0
        font {
          family: Theme.font
          pixelSize: Theme.fontSize
          weight: Theme.fontWeight
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggle()
    }
  }
}
