import QtQml

// Lifecycle of one lazily created overlay window.
//   open     the overlay should be shown (drives its enter/exit animation)
//   mounted  the window exists; stays true until the exit animation finishes
//   screen   where it was opened; fixed until it is closed
QtObject {
  property bool open: false
  property bool mounted: false
  property var screen: null

  function toggle(targetScreen) {
    if (open) {
      open = false
      return
    }
    if (!mounted) screen = targetScreen
    mounted = true
    open = true
  }

  function close() { open = false }

  // Called by the overlay once its exit animation is done. Deferred so the
  // window is not destroyed from inside its own animation callback.
  function unmount() {
    Qt.callLater(() => { if (!open) mounted = false })
  }
}
