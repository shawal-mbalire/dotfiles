// Domain/Ports/NotificationFeedPort.qml
// CONTRACT — NotificationFeedPort
//   var    active        live toasts, newest last (bounded by MAX_VISIBLE)
//                        entry: { key, appName, appIcon, summary, body,
//                                 urgency, critical, isTransient,
//                                 durationMs, expiresAt, paused }
//   var    history       recent non-transient entries, newest first
//                        entry: { key, appName, summary, body, critical, receivedAt }
//   double now           current time (ms), ticks while toasts are live
//   function dismiss(int key)         user-initiated close
//   function expire(int key)          timeout-driven close
//   function invokeDefault(int key)   run the "default" action; returns bool
//   function hasDefaultAction(int key)
//   function pause(int key) / resume(int key)
//   function clearHistory()
//   function dismissAll()
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property var active: []
  property var history: []
  property double now: 0

  function dismiss(key) {}
  function expire(key) {}
  function invokeDefault(key) { return false }
  function hasDefaultAction(key) { return false }
  function pause(key) { return false }
  function resume(key) { return false }
  function clearHistory() {}
  function dismissAll() {}
}
