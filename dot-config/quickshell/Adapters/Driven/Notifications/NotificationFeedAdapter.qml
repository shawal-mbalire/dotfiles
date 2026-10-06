// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/
// Adapters/Driven/Notifications/NotificationFeedAdapter.qml
// Driven adapter: NotificationFeedPort ← NotificationServer. Owns the D-Bus
// daemon, the active toast list, the short history, and all timing. Views only
// render `active` / `history` and call intents; the raw Notification object
// never leaves this file (kept private in `refs`).
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../../../Domain/Ports"
import "../../../Domain/Constants"

NotificationFeedPort {
  id: root

  property int nextKey: 1
  property var refs: ({})

  function urgencyName(urgency) {
    if (urgency === NotificationUrgency.Critical) return "critical"
    if (urgency === NotificationUrgency.Low) return "low"
    return "normal"
  }

  NotificationServer {
    id: server
    keepOnReload: true

    onNotification: function(notification) {
      notification.tracked = true
      root.absorb(notification)
    }
  }

  function absorb(notification) {
    const durationMs = NotificationPolicy.timeoutFor(root.urgencyName(notification.urgency), notification.expireTimeout)
    const key = nextKey++
    refs[key] = notification
    notification.closed.connect(() => root.remove(key))

    const entry = {
      key: key,
      appName: notification.appName || "Unknown",
      appIcon: notification.appIcon || "",
      summary: notification.summary || "",
      body: notification.body || "",
      urgency: notification.urgency,
      critical: notification.urgency === NotificationUrgency.Critical,
      isTransient: notification.transient,
      durationMs: durationMs,
      expiresAt: durationMs > 0 ? Date.now() + durationMs : 0,
      remainingMs: durationMs,
      paused: false
    }

    const next = active.concat([entry])
    const overflow = next.slice(0, Math.max(0, next.length - NotificationPolicy.maxVisible))
    active = next.slice(-NotificationPolicy.maxVisible)
    for (let i = 0; i < overflow.length; ++i) root.expire(overflow[i].key)

    if (!entry.isTransient) {
      history = [{
        key: key,
        appName: entry.appName,
        summary: entry.summary,
        body: entry.body,
        critical: entry.critical,
        receivedAt: new Date()
      }].concat(history).slice(0, NotificationPolicy.maxHistory)
    }
  }

  function remove(key) {
    delete refs[key]
    active = active.filter(e => e.key !== key)
  }

  function entryFor(key) {
    return active.find(e => e.key === key) ?? null
  }

  function dismiss(key) {
    const ref = refs[key]
    if (ref && typeof ref.dismiss === "function") ref.dismiss()
  }

  function expire(key) {
    const ref = refs[key]
    if (ref && typeof ref.expire === "function") ref.expire()
  }

  function defaultAction(key) {
    const ref = refs[key]
    if (!ref) return null
    const actions = ref.actions
    for (let i = 0; i < actions.length; ++i)
      if (actions[i].identifier === "default") return actions[i]
    return null
  }

  function hasDefaultAction(key) { return defaultAction(key) !== null }
  function invokeDefault(key) {
    const action = defaultAction(key)
    if (action === null) return false
    action.invoke()
    return true
  }

  function pause(key) {
    const e = entryFor(key)
    if (!e || e.paused || e.expiresAt <= 0) return false
    e.remainingMs = Math.max(0, e.expiresAt - now)
    e.paused = true
    return true
  }

  function resume(key) {
    const e = entryFor(key)
    if (!e || !e.paused) return false
    e.expiresAt = now + e.remainingMs
    e.paused = false
    return true
  }

  function clearHistory() { history = [] }
  function dismissAll() { active.slice().forEach(e => root.dismiss(e.key)) }

  Timer {
    interval: 100
    running: active.length > 0
    repeat: true
    onTriggered: {
      root.now = Date.now()
      const due = active.filter(e => !e.paused && e.expiresAt > 0 && root.now >= e.expiresAt)
      for (let i = 0; i < due.length; ++i) root.expire(due[i].key)
    }
  }
}
