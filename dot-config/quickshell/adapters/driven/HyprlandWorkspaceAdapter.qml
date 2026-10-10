// WorkspacePort over Quickshell.Hyprland. Hyprland objects stop here: the
// workspace list is reduced to ids, and focus is dispatched in the syntax the
// running config expects (Lua config takes Lua dispatcher expressions).
import QtQml
import Quickshell.Hyprland
import "../../domain/ports"
import "../../domain/constants"
import "../../domain/errors"

WorkspacePort {
  id: root

  count: WorkspacePolicy.count
  focusedId: Hyprland.focusedWorkspace?.id ?? 0
  occupiedIds: Hyprland.workspaces.values.map(ws => ws.id)

  function focus(id) {
    Errors.precondition(WorkspacePolicy.isValidId(id), "workspace.id-out-of-range",
                        "focus needs a workspace id in the strip", { id: id, count: count })
    Hyprland.dispatch(Hyprland.usingLua
      ? "hl.dsp.focus({ workspace = " + id + " })"
      : "workspace " + id)
  }
}
