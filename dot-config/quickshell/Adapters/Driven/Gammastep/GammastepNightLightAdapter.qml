// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/
// Adapters/Driven/Gammastep/GammastepNightLightAdapter.qml
// Driven adapter: NightLightPort ← gammastep. gammastep has no Quickshell
// service, so this is the one fallback adapter allowed to shell out.
import Quickshell
import Quickshell.Io
import QtQuick
import "../../../Domain/Ports"

NightLightPort {
  id: root

  Process {
    id: detectProc
    command: ["pgrep", "gammastep"]
    running: false
    onExited: exitCode => { root.active = exitCode === 0 }
  }

  Process {
    id: setProc
    running: false
    onExited: if (!detectProc.running) detectProc.running = true
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: if (!detectProc.running) detectProc.running = true
  }

  Component.onCompleted: if (!detectProc.running) detectProc.running = true

  function setActive(value) {
    setProc.command = value
      ? ["gammastep", "-m", "wayland", "-O", "16000"]
      : ["killall", "gammastep"]
    setProc.running = false
    setProc.running = true
  }
}
