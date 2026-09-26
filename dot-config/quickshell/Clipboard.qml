import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root
  screen: Quickshell.screens[0]

  property var history: []
  property int maxItems: 20
  property bool ignoreNext: false
  property string lastClip: ""

  anchors {
    top: true
    right: true
  }

  margins.top: 40
  margins.right: 8

  implicitWidth: 320
  implicitHeight: Math.min(history.length * 44 + 50, 16 * 44 + 50)
  color: "transparent"

  WlrLayershell.namespace: "quickshell:clipboard"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0
  visible: false

  property string clipboardText: ""

  Timer {
    interval: 200
    running: true
    repeat: true
    onTriggered: {
      const proc = clipReadProc
      proc.running = false
      proc.running = true
    }
  }

  Process {
    id: clipReadProc
    command: ["wl-paste", "-n"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        if (root.ignoreNext) return
        if (data === root.lastClip) return
        root.lastClip = data
        if (!data || data.trim() === "") return
        root.addToHistory(data)
      }
    }
  }

  function addToHistory(text) {
    for (let i = 0; i < root.history.length; i++) {
      if (root.history[i] === text) {
        root.history.splice(i, 1)
        break
      }
    }
    root.history.unshift(text)
    if (root.history.length > root.maxItems)
      root.history = root.history.slice(0, root.maxItems)
  }

  Process {
    id: copyProc
    command: ["bash", "-c", ""]
    running: false
    onRunningChanged: {
      if (!running) root.visible = false
    }
  }

  function copyAndHide(text) {
    root.ignoreNext = true
    copyProc.command = ["bash", "-c", "printf '%s' '" + text.replace(/'/g, "'\\''") + "' | wl-copy"]
    copyProc.running = false
    copyProc.running = true
    ignoreTimer.restart()
  }

  Timer {
    id: ignoreTimer
    interval: 500
    onTriggered: root.ignoreNext = false
  }

  Rectangle {
    anchors.fill: parent
    color: colorBase
    radius: 10

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 6

      Text {
        text: "Clipboard"
        color: colorText
        font { family: themeFont; pixelSize: 14; weight: 800 }
        Layout.bottomMargin: 2
      }

      Repeater {
        model: root.history

        Rectangle {
          required property string modelData
          required property int index

          Layout.fillWidth: true
          height: 36
          radius: 6
          color: clipMouse.containsMouse ? colorSurface1 : colorSurface0

          Text {
            anchors.fill: parent
            anchors.margins: 8
            text: modelData
            color: colorText
            font { family: themeFont; pixelSize: 12; weight: 600 }
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }

          MouseArea {
            id: clipMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.copyAndHide(modelData)
          }
        }
      }

      Text {
        text: root.history.length === 0 ? "Empty" : ""
        color: colorOverlay0
        font { family: themeFont; pixelSize: 12; weight: 600 }
        visible: root.history.length === 0
      }
    }
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void {
      root.visible = !root.visible
    }
  }
}
