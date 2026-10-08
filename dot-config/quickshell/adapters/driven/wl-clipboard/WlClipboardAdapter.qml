// ClipboardPort over wl-clipboard. `wl-paste --watch` is a single long-lived
// process that reports each new text selection (image copies are skipped by
// --type text without stopping the watch). Quickshell.clipboardText is not
// used for reading because on Wayland it is empty unless a shell window has
// focus. History is persisted to `storePath` as a JSON array.
import QtQml
import Quickshell
import Quickshell.Io
import "../../../domain/ports"
import "../../../domain/models/clipboard.js" as Clip

ClipboardPort {
  id: root

  required property string storePath
  property int maxItems: 50
  property int restartBaseDelay: 1000
  property int restartMaxDelay: 30000
  property int failStreak: 0
  property bool restored: false

  // ASCII record separator between clipboard payloads.
  readonly property string separator: "\x1e"

  // Sensitive selections (password managers) emit an empty record; empty
  // records are dropped by isUsableText.
  readonly property string watchScript: '[ "$CLIPBOARD_STATE" = sensitive ] || cat; printf "\\036"'

  function record(text) {
    if (!Clip.isUsableText(text)) return
    history = Clip.pushUnique(history, text, maxItems)
    state = "ready"
    saveTimer.restart()
  }

  function copy(text) {
    if (!Clip.isUsableText(text)) return
    // Detached: wl-copy forks a server that must outlive this call (and reloads).
    Quickshell.execDetached(["wl-copy", "--", text])
    record(text)
  }

  function remove(text) {
    history = history.filter(t => t !== text)
    saveTimer.restart()
  }

  function clear() {
    history = []
    saveTimer.restart()
  }

  FileView {
    id: store
    path: root.storePath
    blockWrites: false
    atomicWrites: true
    printErrors: false

    onLoaded: {
      try {
        const saved = Clip.restore(JSON.parse(text()), root.maxItems)
        // Anything copied before the file finished loading stays on top.
        root.history = root.history.concat(saved.filter(t => !root.history.includes(t))).slice(0, root.maxItems)
        if (root.history.length > 0) root.state = "ready"
      } catch (e) {
        console.warn("[clipboard] ignoring unreadable history at", path, e)
      }
      root.restored = true
    }
    onSaveFailed: error => console.warn("[clipboard] cannot save history:", error)
    // Missing on first run; anything else is worth a log line.
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn("[clipboard] cannot read history:", error)
      root.restored = true
    }
  }

  Timer {
    id: saveTimer
    interval: 1000
    onTriggered: {
      if (!root.restored) return saveTimer.restart()
      store.setText(JSON.stringify(root.history))
    }
  }

  Process {
    id: watchProc
    command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", root.watchScript]
    running: true
    stdout: SplitParser {
      splitMarker: root.separator
      onRead: data => {
        root.failStreak = 0
        if (root.state === "loading") root.state = "ready"
        root.record(data)
      }
    }
    onStarted: if (root.state === "unavailable") root.state = root.history.length > 0 ? "ready" : "loading"
    onExited: exitCode => {
      root.failStreak++
      console.warn("[clipboard] wl-paste --watch exited with", exitCode, "- restart", root.failStreak)
      if (root.failStreak >= 3) root.state = "unavailable"
      restartTimer.interval = Math.min(root.restartMaxDelay, root.restartBaseDelay * Math.pow(2, root.failStreak - 1))
      restartTimer.restart()
    }
  }

  // Keep retrying with backoff: at login the watcher can start before the
  // compositor is ready, and giving up would leave the clipboard dead.
  Timer {
    id: restartTimer
    onTriggered: watchProc.running = true
  }
}
