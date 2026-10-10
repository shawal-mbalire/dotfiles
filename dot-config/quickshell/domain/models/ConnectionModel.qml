pragma Singleton
import QtQml

// Connection notices. A snapshot is the set of connected endpoints, each
// [{ key, label }]: a Bluetooth device keyed by address, the Wi-Fi network keyed
// by SSID. A null previous snapshot means nothing has been observed yet, so the
// first observation reports nothing.
QtObject {
  function keysOf(snapshot) {
    return new Set(snapshot.map(entry => entry.key))
  }

  function transitions(prev, next) {
    if (prev === null) return []
    const before = keysOf(prev)
    const after = keysOf(next)
    const changes = []
    next.forEach(entry => {
      if (!before.has(entry.key)) changes.push({ label: entry.label, connected: true })
    })
    prev.forEach(entry => {
      if (!after.has(entry.key)) changes.push({ label: entry.label, connected: false })
    })
    return changes
  }

  function noticeFor(appName, change) {
    return {
      appName: appName,
      summary: change.connected ? "Connected" : "Disconnected",
      body: change.label
    }
  }
}
