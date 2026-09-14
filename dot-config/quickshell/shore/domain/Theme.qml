pragma Singleton

import QtQuick
import Quickshell

// Single source of truth for colour, type and metrics.
// Palette is Catppuccin Mocha, matching dot-config/waybar/style.css.
Singleton {
    // ── Palette ───────────────────────────────────────────────────────────
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color flamingo: "#f2cdcd"

    // ── Type ──────────────────────────────────────────────────────────────
    readonly property string fontFamily: "Sono Medium"
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // ── Metrics ───────────────────────────────────────────────────────────
    readonly property int barHeight: 26
    readonly property int radius: 9
    readonly property int gap: 2
    readonly property int padH: 10

    // ── Nerd Font glyphs ─────────────────────────────────────────────────
    readonly property string iconClock: "\uF017"
    readonly property string iconNetwork: "\uF1EB"
    readonly property string iconWired: "\uF6FF"
    readonly property string iconVolume: "\uF028"
    readonly property string iconVolumeMuted: "\uF026"
    readonly property string iconHeadphones: "\uF025"
    readonly property string iconMicrophone: "\uF130"
    readonly property string iconBrightness: "\uF185"
    readonly property string iconBattery: "\uF240"
    readonly property string iconBluetooth: "\uF293"
    readonly property string iconNight: "\uF186"
    readonly property string iconBell: "\uF0F3"
    readonly property string iconBellDnd: "\uF1F6"
    readonly property string iconPower: "\u23FB"
    readonly property string iconDisplay: "\uF108"
    readonly property string iconLock: "\uF023"
    readonly property string iconWifi: "\uF1EB"

    // Alpha-blend a colour (Qt.rgba takes 0..1).
    function tint(colour, alpha) {
        return Qt.rgba(colour.r, colour.g, colour.b, alpha);
    }
}
