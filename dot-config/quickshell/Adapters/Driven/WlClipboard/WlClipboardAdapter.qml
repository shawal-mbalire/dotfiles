// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/Process
// Adapters/Driven/WlClipboard/WlClipboardAdapter.qml
// Driven adapter: ClipboardPort ← wl-clipboard. Polls wl-paste for history and
// writes through wl-copy. History lives in a PersistentProperties so it survives
// config reloads (Quickshell reloads on every file change). The self-induced
// change after a copy is ignored for a short window so it is not re-added.
import Quickshell
import Quickshell.Io
import QtQuick
import "../../../Domain/Ports"
import "../../../Domain/Constants"

ClipboardPort {
  id: root

  // Persists across reloads — recent clips are not lost when the shell's QML
  // graph is rebuilt. Docs:
  // https://quickshell.org/docs/v0.3.0/types/Quickshell/PersistentProperties
  PersistentProperties {
    id: persist
    reloadableId: "clipboardHistory"
    property var history: []
  }

  history: persist.history

  property double ignoreUntil: 0
  property string lastClip: ""
  property int failStreak: 0

  Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: if (!readProc.running) readProc.running = true
  }

  Process {
    id: readProc
    command: ["wl-paste", "-n"]
    running: false
    stdout: StdioCollector {
      id: readOut
      onStreamFinished: {
        if (Date.now() < root.ignoreUntil) return
        const text = readOut.text
        if (text === root.lastClip) return
        root.lastClip = text
        if (!ClipboardPolicy.isUsableText(text)) return
        persist.history = ClipboardPolicy.addToHistory(persist.history, text, ClipboardPolicy.maxItems)
        root.available = true
        root.failStreak = 0
      }
    }
    onExited: exitCode => {
      if (exitCode === 0) {
        root.failStreak = 0
        root.available = true
      } else {
        root.failStreak++
        if (root.failStreak >= 3) root.available = false
      }
    }
  }

  Process {
    id: writeProc
    command: ["wl-copy"]
    running: false
  }

  function copy(text) {
    // Record what we are about to write so the follow-up poll treats it as
    // already-known instead of re-adding it.
    root.lastClip = text
    root.ignoreUntil = Date.now() + 800
    writeProc.command = ["wl-copy", "--", text]
    writeProc.running = false
    writeProc.running = true
    persist.history = ClipboardPolicy.addToHistory(persist.history, text, ClipboardPolicy.maxItems)
  }

  function clear() { persist.history = [] }
}
