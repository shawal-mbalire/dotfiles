pragma Singleton
import QtQml

// domain/constants/WallpaperPolicy.qml
// Pure wallpaper policy: supported extensions, directory-listing parsing, and
// selection math. No Quickshell, no filesystem, no RNG — the adapter supplies
// the random unit value, so every function here is deterministic.
QtObject {
  readonly property var extensions: ["jpg", "jpeg", "png", "webp"]

  function isSupported(path) {
    if (!path) return false
    const dot = path.lastIndexOf(".")
    if (dot <= 0) return false
    return extensions.indexOf(path.slice(dot + 1).toLowerCase()) >= 0
  }

  function joinPath(dir, name) {
    if (!dir) return name
    return dir.charAt(dir.length - 1) === "/" ? dir + name : dir + "/" + name
  }

  // Turn one `ls` line into an absolute path when it names a supported image,
  // otherwise "". A leading-dot file (e.g. ".bashrc") has no usable extension.
  function parseListing(line, dir) {
    const name = (line || "").trim()
    if (name === "") return ""
    if (!isSupported(name)) return ""
    return joinPath(dir, name)
  }

  // Index math mirrors the original `(i +/- 1 + n) % n`, normalised for negatives.
  function nextIndex(index, length) {
    if (length <= 0) return -1
    return ((index + 1) % length + length) % length
  }

  function prevIndex(index, length) {
    if (length <= 0) return -1
    return ((index - 1) % length + length) % length
  }

  // unitRandom must be in [0, 1); values outside are clamped so the result is
  // always a valid index.
  function randomIndex(length, unitRandom) {
    if (length <= 0) return -1
    const r = (unitRandom >= 0 && unitRandom < 1) ? unitRandom : 0
    return Math.floor(r * length)
  }
}
