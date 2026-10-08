.pragma library

const TAB = 9
const LF = 10
const CR = 13
const FIRST_PRINTABLE = 32

// wl-copy receives the text as one argv entry, and Linux caps a single
// argument at 128 KiB; 32k chars stays under that even at 4 bytes/char.
const MAX_CHARS = 32000

// Rejects empty text, binary payloads (control chars other than tab/newlines)
// and blobs too large to copy back.
function isUsableText(text) {
  if (!text || text.trim() === "") return false
  if (text.length > MAX_CHARS) return false
  for (let i = 0; i < text.length; i++) {
    const c = text.charCodeAt(i)
    if (c < FIRST_PRINTABLE && c !== TAB && c !== LF && c !== CR) return false
  }
  return true
}

// Newest first, no duplicates, at most `limit` entries.
function pushUnique(history, text, limit) {
  return [text].concat(history.filter(t => t !== text)).slice(0, limit)
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
