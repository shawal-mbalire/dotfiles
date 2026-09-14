pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../infra"

// Driven adapter: the session list offered at login. Reads the standard
// wayland-sessions directory so it follows whatever the host actually ships,
// and picks Config.defaultSession as the initial choice. Changing it is a
// one-off for the current login only; nothing is persisted.
Singleton {
    id: root

    // [{ name: string, argv: [string] }]
    property var entries: []
    property int selected: 0

    function refresh() {
        if (!scan.running) scan.running = true;
    }

    // .desktop Exec lines are shell-ish and may carry field codes (%U, %f...).
    // greetd execs the list directly, so strip the codes.
    function argvOf(exec) {
        return exec.split(/\s+/).filter(t => t !== "" && t.charAt(0) !== "%");
    }

    function preselect(list) {
        const target = Config.defaultSession.toLowerCase();
        for (let i = 0; i < list.length; i++) {
            if (list[i].name.toLowerCase().indexOf(target) >= 0) {
                root.selected = i;
                return;
            }
        }
        root.selected = 0;
    }

    Process {
        id: scan
        command: ["sh", "-c",
            "for f in \"$1\"/*.desktop; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  n=$(sed -n 's/^Name=//p' \"$f\" | head -n1); " +
            "  e=$(sed -n 's/^Exec=//p' \"$f\" | head -n1); " +
            "  t=$(sed -n 's/^TryExec=//p' \"$f\" | head -n1); " +
            "  if [ -n \"$t\" ]; then command -v \"$t\" >/dev/null 2>&1 || continue; fi; " +
            "  [ -n \"$n\" ] && [ -n \"$e\" ] && printf '%s\\t%s\\n' \"$n\" \"$e\"; " +
            "done", "sh", Config.sessionsDir]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const list = [];
                const text = out.text.trim();
                if (text !== "") {
                    for (const line of text.split("\n")) {
                        const tab = line.indexOf("\t");
                        if (tab < 0) continue;
                        const name = line.slice(0, tab);
                        const exec = line.slice(tab + 1).trim();
                        if (exec === "") continue;
                        list.push({ name: name, argv: root.argvOf(exec) });
                    }
                }
                root.entries = list;
                root.preselect(list);
            }
        }
    }

    Component.onCompleted: refresh()
}
