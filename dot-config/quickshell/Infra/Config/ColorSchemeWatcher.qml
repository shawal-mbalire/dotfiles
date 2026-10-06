// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/Process
// Infra/Config/ColorSchemeWatcher.qml
// Cross-cutting config plumbing: keeps Theme.darkMode in sync with the desktop
// colour-scheme at startup and when it changes outside the shell. The parsing is
// pure (Domain/Constants/ColorScheme.qml); this is the only place the gsettings process
// is driven, so shell.qml stays pure wiring.
import Quickshell.Io
import QtQuick
import "../../Shared"
import "../../Domain/Constants"

Item {
  id: root
  visible: false

  function apply(line) {
    const mode = ColorScheme.modeForLine(line)
    if (mode === ColorScheme.dark) Theme.darkMode = true
    else if (mode === ColorScheme.light) Theme.darkMode = false
  }

  Process {
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser { onRead: data => root.apply(data) }
  }

  Process {
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser { onRead: data => root.apply(data) }
  }
}
