// CONTRACT — WorkspacePort (the compositor's workspace strip)
//   int        count        number of workspaces the strip shows          (read-only)
//   int        focusedId    id of the focused workspace, 0 when none      (read-only)
//   list<int>  occupiedIds  ids of workspaces that hold windows           (read-only)
//   focus(int id)
//     Pre:  id is an integer in 1..count (ValidationError otherwise).
//     Post: workspace id is focused. Backend failures are logged, not thrown.
//   Invariant: occupiedIds holds positive integers, without duplicates.
import QtQml

QtObject {
  property int count: 0
  property int focusedId: 0
  property var occupiedIds: []

  default property list<QtObject> resources

  function focus(id) {}
}
