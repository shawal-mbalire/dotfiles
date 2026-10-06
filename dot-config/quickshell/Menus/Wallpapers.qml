// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/IpcHandler
// Menus/Wallpapers.qml
// Admin entry point for wallpapers (keybinds call `qs ipc call wallpapers …`).
// It owns no I/O: it only exposes WallpaperPort intents over IPC.
import "../Domain/Ports"
import Quickshell.Io
import QtQuick

Item {
  id: root
  visible: false

  required property WallpaperPort wallpaperPort

  IpcHandler {
    target: "wallpapers"

    function refresh(): void { root.wallpaperPort.refresh() }
    function set(path: string): void { root.wallpaperPort.set(path) }
    function next(): void { root.wallpaperPort.next() }
    function prev(): void { root.wallpaperPort.previous() }
    function random(): void { root.wallpaperPort.random() }
    function list(): string { return root.wallpaperPort.wallpapers.join("\n") }
    function current(): string { return root.wallpaperPort.current }
  }
}
