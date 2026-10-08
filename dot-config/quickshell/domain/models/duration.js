.pragma library

const SECONDS_PER_HOUR = 3600
const SECONDS_PER_MINUTE = 60

// 3900 -> "1h 5m", 600 -> "10m", <= 0 or non-finite -> ""
function humanize(seconds) {
  if (!Number.isFinite(seconds) || seconds <= 0) return ""
  const hours = Math.floor(seconds / SECONDS_PER_HOUR)
  const minutes = Math.round((seconds % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE)
  return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m"
}
