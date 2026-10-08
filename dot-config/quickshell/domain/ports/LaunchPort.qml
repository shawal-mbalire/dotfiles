// CONTRACT — LaunchPort (installed applications)
//   list<AppEntry> apps   sorted by name                        (read-only)
//     AppEntry = { id, name, genericName, comment, keywords: [string], iconSource }
//     iconSource is a ready-to-use Image source, "" when the icon is missing.
//   bool launch(string id)
//     Pre:  id comes from `apps`.
//     Post: true and the app is started detached, or false (logged) for an unknown id.
//   Invariant: every AppEntry has a non-empty id and name.
import QtQml

QtObject {
  property var apps: []

  default property list<QtObject> resources

  function launch(id) { return false }
}
