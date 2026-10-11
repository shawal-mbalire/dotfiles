// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell/
// infra/config/Config.qml
// The only place environment / shell config is read (AGENTS.md §6). Adapters and
// views receive values from here; they never call Quickshell.env themselves.
// The QS_* values are exported by hypr/lua/env.lua, the single source for them.
pragma Singleton
import Quickshell
import QtQuick

QtObject {
  readonly property string home: Quickshell.env("HOME")
  readonly property string wallpaperDir: home + "/wallpapers"
  // node.name of the sink to keep as default (see `wpctl status`); "" leaves the system choice.
  readonly property string preferredSink: Quickshell.env("QS_PREFERRED_SINK") || ""
  // Backlight device under /sys/class/backlight.
  readonly property string backlight: Quickshell.env("QS_BACKLIGHT") || "intel_backlight"
  // gammastep colour temperature (Kelvin) for the colour-correction toggle.
  readonly property int colorTemperature: parseInt(Quickshell.env("QS_COLOR_TEMPERATURE")) || 16000
}
