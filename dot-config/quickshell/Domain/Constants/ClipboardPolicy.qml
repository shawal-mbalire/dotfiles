pragma Singleton
import QtQml

// Domain/Constants/ClipboardPolicy.qml
// Pure clipboard-text policy. No Quickshell.
QtObject {
  readonly property int maxItems: 20
  readonly property int maxLength: 200000

  // Reject binary/image payloads (wl-paste will hand over a PNG happily) and
  // absurdly large blobs. Tab, LF and CR are the only control chars text needs.
  function isUsableText(text) {
    if (!text || text.trim() === "") return false
    if (text.length > maxLength) return false
    for (var i = 0; i < text.length; i++) {
      var c = text.charCodeAt(i)
      if (c < 32 && c !== 9 && c !== 10 && c !== 13) return false
    }
    return true
  }

  // Move `text` to the front, de-duplicating, capped at `limit`.
  function addToHistory(history, text, limit) {
    var next = history.filter(function (t) { return t !== text })
    next.unshift(text)
    if (next.length > limit) next = next.slice(0, limit)
    return next
  }
}
