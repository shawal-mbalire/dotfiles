pragma Singleton

import QtQuick
import Quickshell
import "../domain"

// Ports: run an operation and report it against the time budget.
// Any operation over budget is logged loudly so regressions are visible.
Singleton {
    function run(name, fn) {
        const start = Time.nowMs();
        const result = fn();
        const ms = Time.elapsedMs(start);

        if (ms > Constants.timeBudgetMs)
            console.warn("[budget] " + name + " took " + ms + "ms (budget " + Constants.timeBudgetMs + "ms)");
        else
            console.log("[time] " + name + " " + ms + "ms");

        return result;
    }
}
