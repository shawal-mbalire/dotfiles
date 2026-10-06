// Domain/Ports/WallpaperPort.qml
// CONTRACT — WallpaperPort
//   var    wallpapers   string[] absolute paths, populated by refresh()
//   string current      currently applied wallpaper path, "" when none
//   function refresh()  re-scan the configured directory
//   function set(string path)
//   function next()
//   function previous()
//   function random()
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property var wallpapers: []
  property string current: ""

  function refresh() {}
  function set(path) {}
  function next() {}
  function previous() {}
  function random() {}
}
