// CONTRACT — NotificationFeedPort (desktop notification popups and history)
//   list<var> popups    live popups, oldest first, at most maxVisible      (read-only)
//     entry: { key, appName, appIcon, image, summary, body, critical,
//              actions: [{ identifier, text }], durationMs, phase }
//     phase: "shown" | "dismiss" | "expire" | "closed"   (anything but "shown" is leaving)
//   list<var> history   newest first, at most maxHistory; transient ones excluded (read-only)
//     entry: { key, appName, summary, body, critical, receivedAt: Date }
//   invoke(key, identifier)
//     Post: a known action is invoked on the sender and the popup leaves as "closed".
//           An unknown identifier falls back to dismiss(key). Unknown key: no-op.
//   dismiss(key)     Post: a shown popup leaves as "dismiss" (user closed it).
//   expire(key)      Post: a shown popup leaves as "expire" (timed out).
//   finish(key)      Post: a leaving popup is removed. The sender is told "dismiss" or
//                    "expire" unless the phase was "closed". Called by the view after
//                    its exit animation.
//   dismissAll()     Post: every shown popup leaves as "dismiss".
//   clearHistory()   Post: history is empty.
//   post(string appName, string summary, string body)
//     Pre:  summary is a non-empty string (ValidationError otherwise).
//     Post: a shown popup and a history entry are added, as for a sender's
//           notification. No sender is involved, so there is nothing to call back.
//   Invariant: at most maxVisible popups; keys are unique; a popup that has left
//   the list is never reported again. Overflow past maxVisible expires immediately.
import QtQml

QtObject {
  property var popups: []
  property var history: []

  default property list<QtObject> resources

  function invoke(key, identifier) {}
  function dismiss(key) {}
  function expire(key) {}
  function finish(key) {}
  function dismissAll() {}
  function clearHistory() {}
  function post(appName, summary, body) {}
}
