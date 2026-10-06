import "../Shared"
import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: root
  visible: false

  property string wallpaperDir: Quickshell.env("HOME") + "/wallpapers"
  property var wallpapers: []
  property string currentWallpaper: ""
  property int currentIndex: -1
  property bool preloadDone: false

  // Applying the first wallpaper in the directory on every shell start would
  // stomp whatever hyprpaper restored, so it is opt-in now.
  property bool autoApply: false

  readonly property list<string> extensions: ["jpg", "jpeg", "png", "webp"]

  signal wallpaperChanged(string path)

  function load() {
    lsProc.running = false
    lsProc.command = ["ls", wallpaperDir]
    lsProc.running = true
  }

  function setWallpaper(path) {
    if (!path || path.length === 0) return
    hyprpaperProc.running = false
    hyprpaperProc.command = ["hyprctl", "hyprpaper", "wallpaper", ", " + path]
    hyprpaperProc.running = true
    currentWallpaper = path
    currentIndex = wallpapers.indexOf(path)
    wallpaperChanged(path)
  }

  function nextWallpaper() {
    if (wallpapers.length === 0) return
    const idx = (currentIndex + 1 + wallpapers.length) % wallpapers.length
    setWallpaper(wallpapers[idx])
  }

  function prevWallpaper() {
    if (wallpapers.length === 0) return
    const idx = (currentIndex - 1 + wallpapers.length) % wallpapers.length
    setWallpaper(wallpapers[idx])
  }

  function randomWallpaper() {
    if (wallpapers.length === 0) return
    const idx = Math.floor(Math.random() * wallpapers.length)
    setWallpaper(wallpapers[idx])
  }

  Process {
    id: lsProc
    stdout: SplitParser {
      onRead: data => {
        const trimmed = data.trim()
        if (trimmed.length === 0) return
        const dot = trimmed.lastIndexOf(".")
        if (dot <= 0) return
        const ext = trimmed.slice(dot + 1).toLowerCase()
        if (!root.extensions.includes(ext)) return
        // Assign a fresh array so bindings on `wallpapers` actually update.
        root.wallpapers = root.wallpapers.concat(root.wallpaperDir + "/" + trimmed)
      }
    }
    onExited: (code, status) => {
      root.preloadDone = true
      if (root.autoApply && root.wallpapers.length > 0 && root.currentIndex === -1) {
        root.setWallpaper(root.wallpapers[0])
      }
    }
  }

  Process {
    id: hyprpaperProc
    onExited: (code, status) => {
      if (code !== 0) {
        console.warn("[Wallpapers] hyprctl hyprpaper failed with code", code)
      }
    }
  }

  IpcHandler {
    target: "wallpapers"

    function set(path: string): void {
      root.setWallpaper(path)
    }

    function next(): void {
      root.nextWallpaper()
    }

    function prev(): void {
      root.prevWallpaper()
    }

    function random(): void {
      root.randomWallpaper()
    }

    function list(): string {
      return root.wallpapers.join("\n")
    }

    function current(): string {
      return root.currentWallpaper
    }
  }

  Component.onCompleted: load()
}
