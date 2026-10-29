import QtQml
import Quickshell
import Quickshell.Io
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

ClipboardPort {
  id: root
  required property string storePath
  property int maxItems: 50; property int restartBaseDelay: 1000; property int restartMaxDelay: 30000
  property int failStreak: 0; property bool restored: false
  readonly property string separator: "\x1e"
  readonly property string watchScript: '[ "$CLIPBOARD_STATE" = sensitive ] || cat; printf "\\036"'

  function persist() { if (root.restored) store.setText(JSON.stringify(root.history)) }

  function record(text) {
    if (!ClipboardModel.isUsableText(text)) return
    history = ClipboardModel.pushUnique(history, text, maxItems)
    Errors.postcondition(ClipboardModel.holdsInvariant(history, maxItems), "clipboard.history-invariant", "history must be usable, unique and bounded", { size: history.length })
    state = "ready"; persist()
  }

  function copy(text) {
    Errors.precondition(ClipboardModel.isUsableText(text), "clipboard.text-unusable", "copy needs usable text", { length: text ? text.length : 0 })
    Quickshell.execDetached(["wl-copy", "--", text]); record(text)
  }

  function remove(text) { history = history.filter(t => t !== text); persist() }
  function clear() { history = []; persist() }
  function startWatch() { if (!watchProc.running) watchProc.running = true }

  function restore() {
    try {
      const saved = ClipboardModel.restore(JSON.parse(store.text() || "[]"), root.maxItems)
      root.history = root.history.concat(saved.filter(t => !root.history.includes(t))).slice(0, root.maxItems)
      if (root.history.length > 0) root.state = "ready"
    } catch (e) {
      console.warn("[clipboard] ignoring unreadable history at", storePath, e)
    }
  }

  FileView {
    id: store; path: root.storePath; blockLoading: true; blockWrites: true; atomicWrites: true
    onLoaded: { root.restore(); root.restored = true; root.startWatch() }
    onLoadFailed: err => { if (err !== FileViewError.FileNotFound) console.warn("[clipboard] cannot read history:", err); root.restored = true; root.startWatch() }
  }

  Process {
    id: watchProc; command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", root.watchScript]; running: false
    stdout: SplitParser {
      splitMarker: root.separator
      onRead: data => { root.failStreak = 0; if (root.state === "loading") root.state = "ready"; root.record(data) }
    }
    onStarted: if (root.state === "unavailable") root.state = root.history.length > 0 ? "ready" : "loading"
    onExited: exitCode => {
      root.failStreak++
      if (root.failStreak >= 3) root.state = "unavailable"
      restartTimer.interval = Math.min(root.restartMaxDelay, root.restartBaseDelay * Math.pow(2, root.failStreak - 1))
      restartTimer.restart()
    }
  }

  Timer { id: restartTimer; onTriggered: root.startWatch() }
}
