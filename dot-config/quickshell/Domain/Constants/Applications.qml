pragma Singleton
import QtQml

// Domain/Constants/Applications.qml
// Pure application-search policy. No Quickshell.
QtObject {
  readonly property int maxResults: 200

  // Filter desktop applications by a case-insensitive query over name + generic
  // name. An empty query returns the first maxResults entries.
  function filter(apps, query) {
    if (!apps) return []
    var q = (query || "").toLowerCase()
    if (q === "") return apps.slice(0, maxResults)
    var out = []
    for (var i = 0; i < apps.length && out.length < maxResults; i++) {
      var a = apps[i]
      var name = (a.name || "").toLowerCase()
      var generic = (a.genericName || "").toLowerCase()
      if (name.indexOf(q) >= 0 || generic.indexOf(q) >= 0) out.push(a)
    }
    return out
  }
}
