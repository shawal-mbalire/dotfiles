pragma Singleton

import QtQuick
import Quickshell

// Infrastructure: deployment-specific values. The only place in the shell that
// reads the environment.
Singleton {
    readonly property string home: Quickshell.env("HOME") || ""

    // External helper (the existing waybar Python hexagon) + hypr CLIs.
    readonly property string python: "python3"
    readonly property string helper: home + "/.config/waybar/scripts/main.py"
    readonly property string displayToggle: home + "/.config/hypr/scripts/toggle_display.py"

    // Backlight hardware window (raw units) mapped to 0-100%.
    readonly property int brightnessRawMin: 30
    readonly property int brightnessRawMax: 30000
}
