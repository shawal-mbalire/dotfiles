pragma Singleton
import QtQml

// domain/constants/WorkspacePolicy.qml
// Pure workspace policy: the strip size and the focus/step math. No Quickshell;
// the adapter supplies the live focused id and occupied ids.
QtObject {
  readonly property int count: 10

  function isValidId(id) {
    return Number.isInteger(id) && id >= 1 && id <= count
  }

  // Highlight workspace 1 when nothing is focused, as the bar always did.
  function activeId(focusedId) {
    return focusedId > 0 ? focusedId : 1
  }

  // Scroll step, clamped to the strip.
  function stepTarget(focusedId, delta) {
    return Math.max(1, Math.min(count, activeId(focusedId) + delta))
  }
}
