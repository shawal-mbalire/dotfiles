pragma Singleton
import QtQml

// Domain/Constants/NotificationPolicy.qml
// Pure notification policy: timeouts, caps, and progress math. No Quickshell.
QtObject {
  readonly property int normalTimeout: 5000
  readonly property int lowTimeout: 4000
  readonly property int maxTimeout: 10000
  readonly property int maxVisible: 5
  readonly property int maxHistory: 20

  // urgency is a vendor-neutral string: "low" | "normal" | "critical".
  // expireTimeout is the raw freedesktop value; <= 60 is treated as seconds.
  function timeoutFor(urgency, expireTimeout) {
    if (urgency === "critical") return 0
    if (expireTimeout <= 0) return urgency === "low" ? lowTimeout : normalTimeout
    var ms = expireTimeout <= 60 ? expireTimeout * 1000 : expireTimeout
    return Math.min(ms, maxTimeout)
  }

  // Fraction of the toast lifetime still remaining, clamped to 0..1. While the
  // toast is paused the bar freezes at `remainingMs`.
  function progressFor(entry, now) {
    if (!entry || entry.durationMs <= 0) return 0
    var end = entry.paused ? now + entry.remainingMs : entry.expiresAt
    return Math.max(0, Math.min(1, (end - now) / entry.durationMs))
  }
}
