pragma Singleton
import QtQml

QtObject {
  readonly property int secondsPerHour: 3600
  readonly property int secondsPerMinute: 60

  // 3900 -> "1h 5m", 600 -> "10m", <= 0 or non-finite -> ""
  function humanize(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0) return ""
    const hours = Math.floor(seconds / secondsPerHour)
    const minutes = Math.round((seconds % secondsPerHour) / secondsPerMinute)
    return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m"
  }
}
