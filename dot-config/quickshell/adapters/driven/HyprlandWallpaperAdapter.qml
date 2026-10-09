// adapters/driven/HyprlandWallpaperAdapter.qml
// Driven adapter: WallpaperPort ← hyprpaper, driven through `hyprctl`. It lists
// a configured directory and applies the chosen image. All path/selection logic
// is pure (domain/constants/WallpaperPolicy.qml); this file is only I/O.
import QtQml
import Quickshell.Io
import "../../domain/ports"
import "../../domain/constants"

WallpaperPort {
  id: root

  // Injected by the composition root — never read from Quickshell.env here.
  property string directory: ""
  property bool autoApply: false
  property int currentIndex: -1
  property bool scanned: false
  property bool started: false

  Process {
    id: listProc
    command: ["ls", root.directory]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const path = WallpaperPolicy.parseListing(data, root.directory)
        if (path === "") return
        root.wallpapers = root.wallpapers.concat(path)
      }
    }
    onExited: (code, status) => {
      root.scanned = true
      if (code !== 0) {
        console.warn("[Wallpaper] listing failed with code", code)
        return
      }
      if (root.autoApply && root.currentIndex === -1 && root.wallpapers.length > 0)
        root.set(root.wallpapers[0])
    }
  }

  Process {
    id: applyProc
    running: false
    onExited: (code, status) => {
      if (code !== 0) console.warn("[Wallpaper] apply failed with code", code)
    }
  }

  function refresh() {
    root.wallpapers = []
    root.scanned = false
    listProc.command = ["ls", root.directory]
    listProc.running = false
    listProc.running = true
  }

  function set(path) {
    if (!path) return
    root.current = path
    root.currentIndex = root.wallpapers.indexOf(path)
    // hyprpaper IPC: "<monitor>,<path>"; an empty monitor applies to all.
    applyProc.command = ["hyprctl", "hyprpaper", "wallpaper", "," + path]
    applyProc.running = false
    applyProc.running = true
  }

  function next() {
    if (root.wallpapers.length === 0) return
    root.set(root.wallpapers[WallpaperPolicy.nextIndex(root.currentIndex, root.wallpapers.length)])
  }

  function previous() {
    if (root.wallpapers.length === 0) return
    root.set(root.wallpapers[WallpaperPolicy.prevIndex(root.currentIndex, root.wallpapers.length)])
  }

  function random() {
    if (root.wallpapers.length === 0) return
    root.set(root.wallpapers[WallpaperPolicy.randomIndex(root.wallpapers.length, Math.random())])
  }

  Component.onCompleted: {
    root.started = true
    if (root.directory !== "") root.refresh()
  }

  onDirectoryChanged: {
    if (root.started && root.directory !== "") root.refresh()
  }
}
