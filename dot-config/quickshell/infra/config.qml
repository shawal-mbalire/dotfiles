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

    // Audio filter tweaker (a PipeWire filter-chain front end).
    readonly property string audioTweaker: "easyeffects"

    // Backlight hardware window (raw units) mapped to 0-100%.
    readonly property int brightnessRawMin: 30
    readonly property int brightnessRawMax: 30000

    // Wallpaper rendered by the shell (replaces hyprpaper). `wallpaperDir` is
    // the stowed ~/wallpapers folder; `wallpaper` is the fallback when empty.
    readonly property string wallpaper: home + "/wallpapers/wallpaper.jpg"
    readonly property string wallpaperDir: home + "/wallpapers"

    // Shared, world-readable copy of the current wallpaper. The SDDM theme
    // (dot-config/sddm/themes/catppuccin-mocha) reads this before login, so
    // the login screen matches the desktop. Written by adapters/Wallpaper.qml;
    // the directory is created by sddm/setup/switch-from-greetd.sh.
    readonly property string greeterWallpaper: "/var/lib/sddm/wallpaper/current"
}
