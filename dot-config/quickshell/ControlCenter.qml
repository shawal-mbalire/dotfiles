import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root
  screen: Quickshell.screens[0]

  property int volume: 50
  property int brightness: 50
  property string networkName: ""
  property bool networkConnected: false

  anchors {
    top: true
    right: true
  }

  margins.top: 40
  margins.right: 8

  implicitWidth: 280
  implicitHeight: 260
  color: "transparent"

  WlrLayershell.namespace: "quickshell:controlcenter"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0
  visible: false

  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: refreshInfo()
  }

  Component.onCompleted: refreshInfo()

  function refreshInfo() {
    volProc.running = true
    brightProc.running = true
    netProc.running = true
  }

  Process {
    id: volProc
    command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d\", $2 * 100}'"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const v = parseInt(data)
        if (!isNaN(v)) root.volume = v
      }
    }
  }

  Process {
    id: brightProc
    command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%k'"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const b = parseInt(data)
        if (!isNaN(b)) root.brightness = b
      }
    }
  }

  Process {
    id: netProc
    command: ["bash", "-c", "nmcli -t -f NAME,TYPE,DEVICE connection show --active | grep wireless | head -1 | cut -d: -f1"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        root.networkName = data.trim()
        root.networkConnected = data.trim() !== ""
      }
    }
  }

  Process {
    id: volSetProc
    command: ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (root.volume / 100)]
    running: false
  }

  Process {
    id: brightSetProc
    command: ["bash", "-c", "brightnessctl set " + root.brightness + "%"]
    running: false
  }

  Rectangle {
    anchors.fill: parent
    color: colorBase
    radius: 10

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      RowLayout {
        spacing: 8

        Text {
          text: "\uf028"
          color: colorYellow
          font { family: themeNerdFont; pixelSize: 14; weight: themeFontWeight }
        }

        Text {
          text: "Volume"
          color: colorText
          font { family: themeFont; pixelSize: 13; weight: 800 }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.volume + "%"
          color: colorOverlay0
          font { family: themeFont; pixelSize: 12; weight: 600 }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: colorSurface0

        Rectangle {
          width: parent.width * (root.volume / 100)
          height: parent.height
          radius: parent.radius
          color: colorYellow

          Behavior on width {
            NumberAnimation { duration: 100 }
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) {
            root.volume = Math.round((mouse.x / width) * 100)
            volSetProc.running = true
          }
        }
      }

      RowLayout {
        spacing: 8

        Text {
          text: "\uf185"
          color: colorText
          font { family: themeNerdFont; pixelSize: 14; weight: themeFontWeight }
        }

        Text {
          text: "Brightness"
          color: colorText
          font { family: themeFont; pixelSize: 13; weight: 800 }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.brightness + "%"
          color: colorOverlay0
          font { family: themeFont; pixelSize: 12; weight: 600 }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: colorSurface0

        Rectangle {
          width: parent.width * (root.brightness / 100)
          height: parent.height
          radius: parent.radius
          color: colorText

          Behavior on width {
            NumberAnimation { duration: 100 }
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) {
            root.brightness = Math.round((mouse.x / width) * 100)
            brightSetProc.running = true
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: colorSurface1 }

      RowLayout {
        spacing: 8

        Text {
          text: "\uf1eb"
          color: colorPink
          font { family: themeNerdFont; pixelSize: 14; weight: themeFontWeight }
        }

        Text {
          text: "Network"
          color: colorText
          font { family: themeFont; pixelSize: 13; weight: 800 }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.networkConnected ? root.networkName : "Disconnected"
          color: root.networkConnected ? colorGreen : colorOverlay0
          font { family: themeFont; pixelSize: 12; weight: 600 }
        }
      }

      Item { Layout.fillHeight: true }
    }
  }

  IpcHandler {
    target: "controlCenter"
    function toggle(): void {
      root.visible = !root.visible
      if (root.visible) refreshInfo()
    }
  }
}
