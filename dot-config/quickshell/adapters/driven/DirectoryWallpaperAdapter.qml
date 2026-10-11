// adapters/driven/DirectoryWallpaperAdapter.qml
// Driven adapter: WallpaperPort over a plain directory. It lists the configured
// directory and tracks which image is current. Drawing the image is a view's job
// (Shared/WallpaperBackground.qml). All path/selection logic is pure
// (domain/constants/WallpaperPolicy.qml); this file is only I/O.
import QtQml
import Quickshell.Io
import "../../domain/ports"
import "../../domain/errors"
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

  function refresh() {
    root.wallpapers = []
    root.scanned = false
    listProc.command = ["ls", root.directory]
    listProc.running = false
    listProc.running = true
  }

  // Pre: path is an entry of `wallpapers`.
  // Post: current == path.
  function set(path) {
    const index = root.wallpapers.indexOf(path)
    Errors.precondition(index >= 0, "wallpaper.unknown", "wallpaper is not in the scanned directory",
                        { path: path })
    root.current = path
    root.currentIndex = index
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
