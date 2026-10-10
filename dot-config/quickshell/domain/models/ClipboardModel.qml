pragma Singleton
import QtQml

// Pure clipboard-history rules: what text may be recorded, how history is
// ordered and bounded, and how persisted data is restored.
QtObject {
  readonly property int tab: 9
  readonly property int lf: 10
  readonly property int cr: 13
  readonly property int firstPrintable: 32

  // wl-copy receives the text as one argv entry, and Linux caps a single
  // argument at 128 KiB; 32k chars stays under that even at 4 bytes/char.
  readonly property int maxChars: 32000

  // Rejects empty text, binary payloads (control chars other than tab/newlines)
  // and blobs too large to copy back.
  function isUsableText(text) {
    if (!text || text.trim() === "") return false
    if (text.length > maxChars) return false
    for (let i = 0; i < text.length; i++) {
      const c = text.charCodeAt(i)
      if (c < firstPrintable && c !== tab && c !== lf && c !== cr) return false
    }
    return true
  }

  // Newest first, no duplicates, at most `limit` entries.
  function pushUnique(history, text, limit) {
    return [text].concat(history.filter(t => t !== text)).slice(0, limit)
  }

  // Invariant of ClipboardPort: usable, unique, and bounded by `limit`.
  function holdsInvariant(history, limit) {
    if (!Array.isArray(history) || history.length > limit) return false
    return history.every(isUsableText) && new Set(history).size === history.length
  }

  // Single-line preview for list rows.
  function preview(text) {
    return text.replace(/\s+/g, " ").trim()
  }

  // Rebuilds a trusted history from persisted data of unknown shape: keeps only
  // usable strings, drops duplicates, preserves order, bounds the length.
  function restore(saved, limit) {
    if (!Array.isArray(saved)) return []
    const out = []
    for (const item of saved) {
      if (typeof item !== "string" || !isUsableText(item) || out.includes(item)) continue
      out.push(item)
      if (out.length >= limit) break
    }
    return out
  }
}
