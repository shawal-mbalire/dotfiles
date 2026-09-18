pragma Singleton

import QtQuick
import Quickshell
import "../models"

// Ports: run an operation and report it against the time budget.
// Any operation over budget is logged loudly so regressions are visible.
// Set verbose to true to log all operations (including under-budget).
Singleton {
    property bool verbose: false

    function run(name, fn) {
        const start = Time.nowMs();
        const result = fn();
        const ms = Time.elapsedMs(start);

        if (ms > Constants.timeBudgetMs)
            console.warn("[budget] " + name + " took " + ms + "ms (budget " + Constants.timeBudgetMs + "ms)");
        else if (root.verbose)
            console.log("[time] " + name + " " + ms + "ms");

        return result;
    }
}
