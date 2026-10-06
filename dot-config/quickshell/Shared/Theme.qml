pragma Singleton
import QtQuick

QtObject {
  property bool darkMode: true

  // Catppuccin Mocha (dark) / Latte (light)
  readonly property color rosewater: darkMode ? "#f5e0dc" : "#dc8a78"
  readonly property color flamingo: darkMode ? "#f2cdcd" : "#dd7878"
  readonly property color pink: darkMode ? "#f5c2e7" : "#ea76cb"
  readonly property color mauve: darkMode ? "#cba6f7" : "#8839ef"
  readonly property color red: darkMode ? "#f38ba8" : "#d20f39"
  readonly property color maroon: darkMode ? "#eba0ac" : "#e64553"
  readonly property color peach: darkMode ? "#fab387" : "#fe640b"
  readonly property color yellow: darkMode ? "#f9e2af" : "#df8e1d"
  readonly property color green: darkMode ? "#a6e3a1" : "#40a02b"
  readonly property color teal: darkMode ? "#94e2d5" : "#179299"
  readonly property color sky: darkMode ? "#89dceb" : "#04a5e5"
  readonly property color sapphire: darkMode ? "#74c7ec" : "#209fb5"
  readonly property color blue: darkMode ? "#89b4fa" : "#1e66f5"
  readonly property color lavender: darkMode ? "#b4befe" : "#7287fd"
  readonly property color text: darkMode ? "#cdd6f4" : "#4c4f69"
  readonly property color subtext1: darkMode ? "#bac2de" : "#5c5f77"
  readonly property color subtext0: darkMode ? "#a6adc8" : "#6c6f85"
  readonly property color overlay2: darkMode ? "#9399b2" : "#7c7f93"
  readonly property color overlay1: darkMode ? "#7f849c" : "#8c8fa1"
  readonly property color overlay0: darkMode ? "#6c7086" : "#9ca0b0"
  readonly property color surface2: darkMode ? "#585b70" : "#acb0be"
  readonly property color surface1: darkMode ? "#45475a" : "#bcc0cc"
  readonly property color surface0: darkMode ? "#313244" : "#ccd0da"
  readonly property color base: darkMode ? "#1e1e2e" : "#eff1f5"
  readonly property color mantle: darkMode ? "#181825" : "#e6e9ef"
  readonly property color crust: darkMode ? "#11111b" : "#dce0e8"

  // Fonts
  readonly property string font: "Comfortaa"
  readonly property string nerdFont: "Hack Nerd Font"
  readonly property int fontSize: 15
  readonly property int fontWeight: 1000

  // Spacing
  readonly property int radius: 10
  readonly property int radiusSm: 6
  readonly property int radiusLg: 14
  readonly property int spacing: 8
  readonly property int spacingSm: 4
  readonly property int spacingLg: 12
  readonly property int padding: 12
  readonly property int paddingSm: 8
  readonly property int paddingLg: 16
}
