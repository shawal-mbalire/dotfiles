// ColorSchemePort over GNOME's org.gnome.desktop.interface color-scheme, driven
// through gsettings. The parsing is pure (domain/constants/ColorScheme.qml).
// Reads at startup, follows external changes through `gsettings monitor`, and
// restarts the monitor if it exits.
import QtQml
import Quickshell
import Quickshell.Io
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/models"
import "../../domain/errors"

ColorSchemePort {
  id: root

  property int failStreak: 0
  property int maxFailures: 5
  property int restartBaseDelay: 2000
  property int restartMaxDelay: 30000

  function applyLine(line) {
    const mode = ColorScheme.modeForLine(line)
    if (mode === ColorScheme.dark) root.darkMode = true
    else if (mode === ColorScheme.light) root.darkMode = false
  }

  // Pre: enabled is a boolean.
  function setDarkMode(enabled) {
    Errors.precondition(Contracts.isBool(enabled), "color-scheme.enabled-type",
                        "darkMode must be a boolean", { enabled: enabled })
    root.darkMode = enabled
    Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
                             enabled ? "prefer-dark" : "prefer-light"])
  }

  Process {
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser { onRead: data => root.applyLine(data) }
  }

  Process {
    id: monitor
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        root.failStreak = 0
        root.applyLine(data)
      }
    }
    onExited: exitCode => {
      root.failStreak++
      if (root.failStreak > root.maxFailures) {
        console.warn("[color-scheme] gsettings monitor failed", root.failStreak, "times; following stopped")
        return
      }
      console.warn("[color-scheme] gsettings monitor exited with", exitCode, "- restart", root.failStreak)
      restartTimer.interval = Math.min(root.restartMaxDelay, root.restartBaseDelay * Math.pow(2, root.failStreak - 1))
      restartTimer.restart()
    }
  }

  // Backs off on repeated failures (e.g. gsettings missing) and gives up after
  // maxFailures, so a broken setup costs a handful of forks, not one every 2 s.
  Timer {
    id: restartTimer
    onTriggered: monitor.running = true
  }
}
