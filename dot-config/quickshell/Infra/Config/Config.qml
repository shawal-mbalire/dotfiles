// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell/
// Infra/Config/Config.qml
// The only place environment / shell config is read (AGENTS.md §6). Adapters and
// views receive values from here; they never call Quickshell.env themselves.
pragma Singleton
import Quickshell
import QtQuick

QtObject {
  readonly property string home: Quickshell.env("HOME")
  readonly property string wallpaperDir: home + "/wallpapers"
}
