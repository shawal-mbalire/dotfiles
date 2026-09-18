pragma Singleton

import QtQuick
import Quickshell

// Driven adapter: application catalog for the launcher.
// Implements the LauncherPort (search / launch).
// Search results are debounced (50ms) so rapid keystrokes don't re-score all
// applications on every character.
Singleton {
    id: root

    readonly property var applications: {
        const all = DesktopEntries.applications.values;
        return all.filter(e => e && e.name && !e.noDisplay);
    }

    // Debounced search state — the panel reads `results` instead of calling
    // search() directly in a binding.
    property string _pendingQuery: ""
    property var _lastResults: []
    property int _revision: 0

    readonly property var results: root._lastResults
    readonly property int resultsRevision: root._revision

    Timer {
        id: debounceTimer
        interval: 50
        onTriggered: root._executeSearch(root._pendingQuery)
    }

    // Fuzzy match: returns score > 0 if every char in q appears in s in order, else 0.
    // Consecutive matches and early positions score higher.
    function _fuzzyScore(s, q) {
        if (q === "") return 1;
        let si = 0, qi = 0, score = 0, consecutive = 0;
        while (si < s.length && qi < q.length) {
            if (s[si] === q[qi]) {
                qi++;
                consecutive++;
                score += consecutive * 10;
            } else {
                consecutive = 0;
            }
            si++;
        }
        return qi === q.length ? score : 0;
    }

    // Score an application against a query. Higher = more relevant.
    function _score(entry, q) {
        const name = (entry.name || "").toLowerCase();
        const gen  = (entry.genericName || "").toLowerCase();
        const cmt  = (entry.comment || "").toLowerCase();
        const kws  = entry.keywords ? entry.keywords.join(" ").toLowerCase() : "";
        const cats = entry.categories ? entry.categories.join(" ").toLowerCase() : "";

        // Exact name match → best
        if (name === q) return 10000;
        // Name starts with query → great
        if (name.indexOf(q) === 0) return 5000 + (q.length / name.length) * 1000;
        // Name contains query → good
        const namePos = name.indexOf(q);
        if (namePos !== -1) return 3000 - namePos + (q.length / name.length) * 500;

        // Fuzzy on name → decent
        const nameFuzzy = _fuzzyScore(name, q);
        if (nameFuzzy > 0) return 2000 + nameFuzzy;

        // Keywords / genericName
        if (kws.indexOf(q) !== -1) return 1500;
        if (gen.indexOf(q) !== -1) return 1200;
        const genFuzzy = _fuzzyScore(gen, q);
        if (genFuzzy > 0) return 1100 + genFuzzy;

        // Categories
        if (cats.indexOf(q) !== -1) return 1000;

        // Comment
        if (cmt.indexOf(q) !== -1) return 800;
        const cmtFuzzy = _fuzzyScore(cmt, q);
        if (cmtFuzzy > 0) return 500 + cmtFuzzy;

        // Fuzzy across full haystack (fallback)
        const hay = (name + " " + gen + " " + cmt + " " + kws + " " + cats);
        return _fuzzyScore(hay, q);
    }

    // Public entry point: debounce rapid calls, execute after quiet period.
    function search(query) {
        root._pendingQuery = (query || "").trim().toLowerCase();
        debounceTimer.restart();
    }

    function _executeSearch(q) {
        const apps = root.applications;
        if (q === "") {
            root._lastResults = apps.slice(0, 8);
        } else {
            root._lastResults = apps
                .map(e => ({ entry: e, score: root._score(e, q) }))
                .filter(r => r.score > 0)
                .sort((a, b) => b.score - a.score)
                .slice(0, 50)
                .map(r => r.entry);
        }
        root._revision++;
    }

    function launch(entry) {
        if (entry) entry.execute();
    }
}
