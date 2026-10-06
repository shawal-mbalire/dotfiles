import "../Shared"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Overlay {
  id: root
  required property var modelData

  title: "Clipboard"
  shellNamespace: "quickshell:clipboard"
  implicitWidth: 340
  implicitHeight: 400
  screen: modelData

  property var history: []
  property int maxItems: 20
  property double ignoreUntil: 0
  property string lastClip: ""
  property string loadState: "loading"
  property int failStreak: 0

  // Never kill an in-flight wl-paste. Restarting it every tick made it time out
  // before it could return any data, which is why history stayed empty.
  Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: if (!clipReadProc.running) clipReadProc.running = true
  }

  Process {
    id: clipReadProc
    command: ["wl-paste", "-n"]
    running: false
    stdout: StdioCollector {
      id: clipOut
      onStreamFinished: {
        if (Date.now() < root.ignoreUntil) return
        const text = clipOut.text
        if (text === root.lastClip) return
        root.lastClip = text
        if (!root.isUsableText(text)) return
        root.addToHistory(text)
        root.loadState = "ready"
        root.failStreak = 0
      }
    }
    onExited: exitCode => {
      if (exitCode === 0) {
        root.failStreak = 0
        if (root.history.length > 0) root.loadState = "ready"
      } else {
        root.failStreak++
        if (root.failStreak >= 3) root.loadState = "unavailable"
      }
    }
  }

  // Reject binary/image payloads (wl-paste will happily hand over a PNG) and
  // absurdly large blobs. Tab, LF and CR are the only control chars text needs.
  function isUsableText(text) {
    if (!text || text.trim() === "") return false
    if (text.length > 200000) return false
    for (let i = 0; i < text.length; i++) {
      const c = text.charCodeAt(i)
      if (c < 32 && c !== 9 && c !== 10 && c !== 13) return false
    }
    return true
  }

  function addToHistory(text) {
    let next = root.history.filter(t => t !== text)
    next.unshift(text)
    if (next.length > root.maxItems) next = next.slice(0, root.maxItems)
    root.history = next
  }

  Process {
    id: copyProc
    command: ["bash", "-c", ""]
    running: false
    onExited: root.closeRequested()
  }

  function copyAndHide(text) {
    // Record what we are about to write so the follow-up poll treats it as
    // already-known instead of re-adding it.
    root.lastClip = text
    root.ignoreUntil = Date.now() + 800
    copyProc.command = ["bash", "-c", "printf '%s' '" + text.replace(/'/g, "'\\''") + "' | wl-copy"]
    copyProc.running = false
    copyProc.running = true
  }

  onVisibleChanged: if (visible && !clipReadProc.running) clipReadProc.running = true

  readonly property string statusText: {
    if (loadState === "unavailable") return "wl-paste not available"
    if (loadState === "loading") return "Reading clipboard..."
    return "Nothing copied yet"
  }

  Shortcut {
    sequence: "Escape"
    onActivated: root.closeRequested()
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.paddingLg
    spacing: Theme.spacingLg

    Text {
      text: "Clipboard"
      color: Theme.text
      font { family: Theme.font; pixelSize: 14; weight: 800 }
      Layout.bottomMargin: Theme.spacingSm
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.history.length > 0
      clip: true
      model: root.history

      delegate: Rectangle {
        required property string modelData
        required property int index
        height: 36
        radius: Theme.radiusSm
        color: clipMouse.containsMouse ? Theme.surface1 : Theme.surface0

        Text {
          anchors.fill: parent
          anchors.margins: Theme.paddingSm
          text: modelData
          color: Theme.text
          font { family: Theme.font; pixelSize: 12; weight: 600 }
          elide: Text.ElideRight
          verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
          id: clipMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.copyAndHide(modelData)
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.history.length === 0

      Text {
        anchors.centerIn: parent
        text: root.statusText
        color: Theme.overlay0
        font { family: Theme.font; pixelSize: 12; weight: 600 }
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
