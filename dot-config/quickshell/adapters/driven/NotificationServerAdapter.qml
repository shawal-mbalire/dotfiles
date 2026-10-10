// NotificationFeedPort over the freedesktop notification daemon
// (Quickshell.Services.Notifications). Vendor Notification objects stop at this
// boundary: popups and history are plain domain values, and the live objects
// stay in the private `refs` map so the sender can be told what the user did.
import QtQml
import Quickshell.Services.Notifications
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

NotificationFeedPort {
  id: root

  property int maxVisible: 5
  property int maxHistory: 20
  property int nextKey: 1
  // key -> live Notification. Never leaves the adapter.
  property var refs: ({})

  function admit(notification) {
    const key = nextKey++
    const actions = []
    for (let i = 0; i < notification.actions.length; i++) {
      const a = notification.actions[i]
      actions.push({ identifier: a.identifier, text: a.text })
    }
    const entry = NotificationModel.popupFrom({
      key: key,
      appName: notification.appName,
      appIcon: notification.appIcon,
      image: notification.image,
      summary: notification.summary,
      body: notification.body,
      critical: notification.urgency === NotificationUrgency.Critical,
      low: notification.urgency === NotificationUrgency.Low,
      actions: actions,
      expireTimeout: notification.expireTimeout
    })

    refs[key] = notification
    show(entry, notification.transient)
    return key
  }

  function show(entry, transient) {
    const admitted = NotificationModel.admit(popups, entry, maxVisible)
    popups = admitted.popups
    admitted.overflow.forEach(item => {
      callRef(item.key, "expire")
      forget(item.key)
    })

    if (!transient) {
      history = NotificationModel.pushHistory(history, entry, new Date(), maxHistory)
    }
  }

  // Pre: summary is non-empty. The notice has no sender, so no ref is kept.
  function post(appName, summary, body) {
    Errors.precondition(Contracts.isNonEmptyString(summary), "notification.summary-empty",
                        "posted notification needs a summary", { appName: appName })
    const key = nextKey++
    show(NotificationModel.popupFrom({
      key: key,
      appName: appName,
      appIcon: "",
      image: "",
      summary: summary,
      body: body,
      critical: false,
      low: false,
      actions: [],
      expireTimeout: 0
    }), false)
  }

  function callRef(key, method) {
    const ref = refs[key]
    if (ref && typeof ref[method] === "function") ref[method]()
  }

  function forget(key) {
    delete refs[key]
  }

  function invoke(key, identifier) {
    const entry = popups.find(item => item.key === key)
    if (!entry) return
    const notification = refs[key]
    const actions = notification ? notification.actions : []
    for (let i = 0; i < actions.length; i++) {
      if (actions[i].identifier === identifier) {
        actions[i].invoke()
        // Resident notifications stay with the sender; the popup still goes.
        popups = NotificationModel.withPhase(popups, key, "closed")
        return
      }
    }
    dismiss(key)
  }

  function dismiss(key) {
    popups = NotificationModel.withPhase(popups, key, "dismiss")
  }

  function expire(key) {
    popups = NotificationModel.withPhase(popups, key, "expire")
  }

  function finish(key) {
    const entry = popups.find(item => item.key === key)
    if (!entry || entry.phase === "shown") return
    if (entry.phase === "dismiss" || entry.phase === "expire") callRef(key, entry.phase)
    popups = NotificationModel.without(popups, key)
    forget(key)
  }

  function dismissAll() {
    popups.slice().forEach(item => dismiss(item.key))
  }

  function clearHistory() {
    history = []
  }

  NotificationServer {
    id: server
    keepOnReload: true
    actionsSupported: true
    imageSupported: true
    bodySupported: true

    onNotification: function(notification) {
      notification.tracked = true
      const key = root.admit(notification)
      notification.closed.connect(() => { root.popups = NotificationModel.withPhase(root.popups, key, "closed") })
    }
  }
}
