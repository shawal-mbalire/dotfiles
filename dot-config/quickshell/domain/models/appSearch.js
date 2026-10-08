.pragma library

// Lower score = better match. Unmatched apps are dropped.
const SCORE_PREFIX = 0
const SCORE_WORD_PREFIX = 1
const SCORE_NAME_CONTAINS = 2
const SCORE_METADATA = 3
const SCORE_SUBSEQUENCE = 4

function isSubsequence(needle, haystack) {
  let j = 0
  for (let i = 0; i < haystack.length && j < needle.length; i++) {
    if (haystack[i] === needle[j]) j++
  }
  return j === needle.length
}

function score(app, q) {
  const name = app.name.toLowerCase()
  if (name.startsWith(q)) return SCORE_PREFIX
  if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return SCORE_WORD_PREFIX
  if (name.includes(q)) return SCORE_NAME_CONTAINS
  const meta = [app.genericName, app.comment].concat(app.keywords || []).join(" ").toLowerCase()
  if (meta.includes(q)) return SCORE_METADATA
  if (q.length > 1 && isSubsequence(q, name)) return SCORE_SUBSEQUENCE
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
