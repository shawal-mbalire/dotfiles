// CONTRACT — WallpaperPort
//   var    wallpapers   string[] absolute paths, populated by refresh()
//   string current      currently applied wallpaper path, "" when none
//   refresh()           re-scan the configured directory into `wallpapers`
//   set(string path)    Pre: path is an entry of `wallpapers` (ValidationError otherwise).
//                       Post: current == path, hyprpaper applied it.
//   next() / previous() step through `wallpapers`, wrapping.
//   random()            apply a uniformly random entry.
//
// "read-only" is by contract: QML forbids a derived type from binding an
// inherited `readonly property`, so ports declare plain properties and only
// adapters may bind them. Consumers never write them.
import QtQml

QtObject {
  property var wallpapers: []
  property string current: ""

  default property list<QtObject> resources

  function refresh() {}
  function set(path) {}
  function next() {}
  function previous() {}
  function random() {}
}
