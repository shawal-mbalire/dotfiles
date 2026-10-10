pragma Singleton
import QtQml

// Lower score = better match. Unmatched apps are dropped.
QtObject {
  readonly property int scorePrefix: 0
  readonly property int scoreWordPrefix: 1
  readonly property int scoreNameContains: 2
  readonly property int scoreMetadata: 3
  readonly property int scoreSubsequence: 4

  function isSubsequence(needle, haystack) {
    let j = 0
    for (let i = 0; i < haystack.length && j < needle.length; i++) {
      if (haystack[i] === needle[j]) j++
    }
    return j === needle.length
  }

  function score(app, q) {
    const name = app.name.toLowerCase()
    if (name.startsWith(q)) return scorePrefix
    if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return scoreWordPrefix
    if (name.includes(q)) return scoreNameContains
    const meta = [app.genericName, app.comment].concat(app.keywords || []).join(" ").toLowerCase()
    if (meta.includes(q)) return scoreMetadata
    if (q.length > 1 && isSubsequence(q, name)) return scoreSubsequence
    return -1
  }

  // Returns the apps matching `query`, best first; ties keep the input order.
  function filter(apps, query) {
    const q = query.trim().toLowerCase()
    if (q === "") return apps
    return apps
      .map((app, index) => ({ app: app, index: index, score: score(app, q) }))
      .filter(r => r.score >= 0)
      .sort((a, b) => a.score - b.score || a.index - b.index)
      .map(r => r.app)
  }
}
