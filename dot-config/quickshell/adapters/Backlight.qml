pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../domain"
import "../infra"

// Driven adapter: backlight via brightnessctl.
// Implements the BrightnessPort (refresh / setPercent / step).
// Maps the hardware raw window (InfraConfig.brightnessRaw*) to 0-100%.
Singleton {
    id: root

    property int raw: 0
    property int percent: 0
    property bool available: false

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function setPercent(value) {
        setProc.command = ["brightnessctl", "s", String(Formatters.percentToRaw(value, InfraConfig.brightnessRawMin, InfraConfig.brightnessRawMax))];
        setProc.running = true;
    }

    function step(delta) {
        root.setPercent(root.percent + delta);
    }

    Process {
        id: proc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                // device,class,current,percent,max
                const parts = out.text.trim().split(",");
                if (parts.length < 5) return;
                const current = parseInt(parts[2], 10);
                const max = parseInt(parts[4], 10);
                if (isNaN(current) || isNaN(max) || max <= 0) {
                    root.available = false;
                    return;
                }
                root.available = true;
                root.raw = current;
                root.percent = Formatters.rawToPercent(current, InfraConfig.brightnessRawMin, InfraConfig.brightnessRawMax);
            }
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {}
        onExited: root.refresh()
    }

    Component.onCompleted: refresh()
}
