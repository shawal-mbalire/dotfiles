.pragma library

const MS_PER_SECOND = 1000
const LOW_TIMEOUT_MS = 4000
const NORMAL_TIMEOUT_MS = 5000
const MAX_TIMEOUT_MS = 10000
// Some senders put seconds in expireTimeout; anything this small is seconds.
const SECONDS_THRESHOLD = 60

// 0 means "stay until dismissed".
function timeoutMs(expireTimeout, isCritical, isLow) {
  if (isCritical) return 0
  let ms
  if (!(expireTimeout > 0)) ms = isLow ? LOW_TIMEOUT_MS : NORMAL_TIMEOUT_MS
  else if (expireTimeout <= SECONDS_THRESHOLD) ms = expireTimeout * MS_PER_SECOND
  else ms = expireTimeout
  return Math.min(ms, MAX_TIMEOUT_MS)
}

// Many senders ignore the advertised capabilities and send markup anyway;
// render it as plain text instead of showing raw tags.
function plainText(text) {
  if (!text) return ""
  return text
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]*>/g, "")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"")
    .replace(/&apos;|&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .trim()
}
