pragma Singleton
import QtQml

// Popup rules: what the shell shows for a notification, how long it stays, and
// how popups and history move. The adapter translates the sender's notification
// into plain fields first; nothing here touches Quickshell.
QtObject {
  readonly property int msPerSecond: 1000
  readonly property int lowTimeoutMs: 4000
  readonly property int normalTimeoutMs: 5000
  readonly property int maxTimeoutMs: 10000
  // Some senders put seconds in expireTimeout; anything this small is seconds.
  readonly property int secondsThreshold: 60

  // Popup phases. Anything but "shown" is an exit in progress: the view plays it
  // and then calls NotificationFeedPort.finish(key).
  //   dismiss  the user closed it (sender is told "dismiss")
  //   expire   it timed out (sender is told "expire")
  //   closed   the sender already closed it (sender is not called back)
  readonly property string phaseShown: "shown"

  // 0 means "stay until dismissed".
  function timeoutMs(expireTimeout, isCritical, isLow) {
    if (isCritical) return 0
    let ms
    if (!(expireTimeout > 0)) ms = isLow ? lowTimeoutMs : normalTimeoutMs
    else if (expireTimeout <= secondsThreshold) ms = expireTimeout * msPerSecond
    else ms = expireTimeout
    return Math.min(ms, maxTimeoutMs)
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

  // fields: { key, appName, appIcon, image, summary, body, critical, low,
  //           actions: [{ identifier, text }], expireTimeout }
  function popupFrom(fields) {
    const appName = fields.appName || "Notification"
    const summary = plainText(fields.summary)
    const body = plainText(fields.body)
    return {
      key: fields.key,
      appName: appName,
      appIcon: fields.appIcon || "",
      image: fields.image || "",
      // Some senders only fill the body; never render an empty card.
      summary: summary !== "" ? summary : (body !== "" ? appName : "New notification"),
      body: body,
      critical: fields.critical,
      actions: fields.actions.filter(a => a.identifier !== "default" && a.text !== ""),
      durationMs: timeoutMs(fields.expireTimeout, fields.critical, fields.low),
      phase: phaseShown
    }
  }

  // Appends a popup. `overflow` holds the oldest popups pushed past maxVisible.
  function admit(popups, entry, maxVisible) {
    const next = popups.concat([entry])
    const cut = Math.max(0, next.length - maxVisible)
    return { popups: next.slice(cut), overflow: next.slice(0, cut) }
  }

  // Only a shown popup can start leaving, so the first exit reason wins.
  function withPhase(popups, key, phase) {
    return popups.map(item => item.key === key && item.phase === phaseShown
      ? Object.assign({}, item, { phase: phase })
      : item)
  }

  function without(popups, key) {
    return popups.filter(item => item.key !== key)
  }

  function pushHistory(history, entry, receivedAt, maxHistory) {
    const item = {
      key: entry.key,
      appName: entry.appName,
      summary: entry.summary,
      body: entry.body,
      critical: entry.critical,
      receivedAt: receivedAt
    }
    return [item].concat(history).slice(0, maxHistory)
  }
}
