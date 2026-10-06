// Domain/Ports/WorkspacePort.qml
// CONTRACT — WorkspacePort
//   var    workspaces   [{ id: int, active: bool }], sorted by id
//   int    focusedId    id of the focused workspace, -1 when unknown
//   function focus(int id)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property var workspaces: []
  property int focusedId: -1

  function focus(id) {}
}
