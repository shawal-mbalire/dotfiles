// CONTRACT — ColorCorrectionPort (screen colour temperature)
//   bool active                                                  (read-only)
//   setActive(bool active)
//     Pre:  active is a boolean (ValidationError otherwise).
//     Post: active == value immediately, re-verified against the system shortly after.
//   refresh()   re-read external state (it can change outside the shell)
import QtQml

QtObject {
  property bool active: false

  default property list<QtObject> resources

  function setActive(value) {}
  function refresh() {}
}
