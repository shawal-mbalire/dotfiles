// ClipboardPort over wl-clipboard. `wl-paste --watch` is a single long-lived
// process that reports each new text selection (image copies are skipped by
// --type text without stopping the watch). Quickshell.clipboardText is not
// used for reading because on Wayland it is empty unless a shell window has
// focus (https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell/).
//
// Persistence: FileView JSON at `storePath`. `blockLoading` makes the restore
// deterministic — history is merged BEFORE the watcher starts, so a new copy
// can never clobber persisted items; `blockWrites` persists every change
// immediately, so the last copy is never lost on exit.
import QtQml
import Quickshell
import Quickshell.Io
import "../../domain/ports"
import "../../domain/models/clipboard.js" as Clip

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

  // Persist immediately (blockWrites) so nothing is lost on reload/exit.
  function persist() {
    if (root.restored) store.setText(JSON.stringify(root.history))
  }

  function record(text) {
    if (!Clip.isUsableText(text)) return
    history = Clip.pushUnique(history, text, maxItems)
    state = "ready"
    persist()
  }

  function copy(text) {
    if (!Clip.isUsableText(text)) return
    // Detached: wl-copy forks a server that must outlive this call (and reloads).
    Quickshell.execDetached(["wl-copy", "--", text])
    record(text)
  }

  function remove(text) {
    history = history.filter(t => t !== text)
    persist()
  }

  function clear() {
    history = []
    persist()
  }

  function startWatch() {
    if (!watchProc.running) watchProc.running = true
  }

  function restore() {
    try {
      const saved = Clip.restore(JSON.parse(store.text() || "[]"), root.maxItems)
      // Anything copied before the file finished loading stays on top.
      root.history = root.history.concat(saved.filter(t => !root.history.includes(t))).slice(0, root.maxItems)
      if (root.history.length > 0) root.state = "ready"
    } catch (e) {
      console.warn("[clipboard] ignoring unreadable history at", storePath, e)
    }
  }

  FileView {
    id: store
    path: root.storePath
    // Restore synchronously before the watcher starts (see header).
    blockLoading: true
    blockWrites: true
    atomicWrites: true

    onLoaded: {
      root.restore()
      root.restored = true
      root.startWatch()
    }
    // Missing on first run; anything else is worth a log line (no silent failure).
    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) console.warn("[clipboard] cannot read history:", error)
      root.restored = true
      root.startWatch()
    }
  }

  Process {
    id: watchProc
    // Started from restore/onLoadFailed, never before persisted history is in.
    command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", root.watchScript]
    running: false
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
    onTriggered: root.startWatch()
  }
}