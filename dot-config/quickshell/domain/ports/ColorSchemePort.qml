// CONTRACT — ColorSchemePort (desktop light/dark preference)
//   bool darkMode                                            (read-only)
//   setDarkMode(bool enabled)
//     Pre:  enabled is a boolean (ValidationError otherwise).
//     Post: darkMode == enabled immediately; re-verified when the desktop reports back.
//   Invariant: darkMode follows the desktop preference, including changes made outside the shell.
import QtQml

QtObject {
  property bool darkMode: true

  default property list<QtObject> resources

  function setDarkMode(enabled) {}
}
