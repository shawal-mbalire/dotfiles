// Domain/Ports/Verify.qml — registry of every port's required surface.
//
// shell.qml calls assertPorts([...]) at startup so an adapter that drifts from
// its contract fails loud instead of misbehaving at runtime. Keep each list in
// sync with the matching *Port.qml header.
import QtQml

QtObject {
  readonly property var batteryPort: ["present", "charging", "level", "state", "timeText"]
  readonly property var bluetoothPort: ["available", "enabled", "connected", "deviceName", "setEnabled"]
  readonly property var brightnessPort: ["level", "setLevel"]
  readonly property var nightLightPort: ["active", "setActive"]
  readonly property var audioPort: ["ready", "muted", "volume", "setVolume", "setMuted"]
  readonly property var networkPort: ["available", "wifiEnabled", "connected", "activeName", "signal", "scanning", "networks", "setWifiEnabled", "scan", "connectTo"]
  readonly property var notificationFeedPort: ["active", "history", "now", "dismiss", "expire", "invokeDefault", "hasDefaultAction", "pause", "resume", "clearHistory", "dismissAll"]
  readonly property var launchPort: ["applications", "launch"]
  readonly property var clipboardPort: ["available", "history", "copy", "clear"]
  readonly property var wallpaperPort: ["wallpapers", "current", "refresh", "set", "next", "previous", "random"]
  readonly property var workspacePort: ["workspaces", "focusedId", "focus"]

  function assertPorts(specs) {
    for (let i = 0; i < specs.length; ++i) {
      const spec = specs[i]
      const missing = spec.methods.filter(name => spec.adapter[name] === undefined)
      if (missing.length > 0)
        console.error("[" + spec.name + "] adapter is missing: " + missing.join(", "))
    }
  }
}
