pragma Singleton
import QtQml

// Domain/Constants/ColorScheme.qml
// Pure parse of `gsettings get/monitor … color-scheme` output. No Quickshell.
QtObject {
  readonly property string dark: "dark"
  readonly property string light: "light"

  // Returns dark, light, or "" when the line carries no known preference.
  function modeForLine(line) {
    if (!line) return ""
    if (line.indexOf("prefer-dark") >= 0) return dark
    if (line.indexOf("prefer-light") >= 0) return light
    return ""
  }
}
