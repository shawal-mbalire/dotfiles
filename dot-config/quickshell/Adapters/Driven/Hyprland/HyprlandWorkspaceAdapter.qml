// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/Hyprland
// Adapters/Driven/Hyprland/HyprlandWorkspaceAdapter.qml
// Driven adapter: WorkspacePort ← Hyprland. Maps Hyprland's workspace model to
// domain entries; `dispatch` (focus) is the only side effect.
import Quickshell.Hyprland
import "../../../Domain/Ports"

WorkspacePort {
  id: root

  readonly property var focused: Hyprland.focusedWorkspace ?? null
  readonly property var models: Hyprland.workspaces ? Hyprland.workspaces.values : []

  workspaces: models
    .map(ws => ({ id: ws.id, active: focused !== null && focused.id === ws.id }))
    .sort((a, b) => a.id - b.id)

  focusedId: focused !== null ? focused.id : -1

  function focus(id) {
    // Hyprland 0.55+ Lua configs use a different dispatcher syntax.
    if (Hyprland.usingLua)
      Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`)
    else
      Hyprland.dispatch(`workspace ${id}`)
  }
}
