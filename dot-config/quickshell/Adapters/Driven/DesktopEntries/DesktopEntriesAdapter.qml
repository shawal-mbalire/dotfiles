// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell/DesktopEntries
// Adapters/Driven/DesktopEntries/DesktopEntriesAdapter.qml
// Driven adapter: LaunchPort ← DesktopEntries. Replaces the previous bash+awk
// scan; Quickshell parses the XDG entries (including flatpak) and Exec.
import Quickshell
import "../../../Domain/Ports"

LaunchPort {
  id: root

  applications: DesktopEntries.applications.values.map(e => ({
    id: e.id,
    name: e.name,
    // Quickshell.iconPath(name, true) returns "" when the theme lacks the icon,
    // so the view can show a placeholder instead of a broken image.
    icon: e.icon !== "" ? Quickshell.iconPath(e.icon, true) : "",
    genericName: e.genericName,
    comment: e.comment
  }))

  function launch(id) {
    const entry = DesktopEntries.byId(id)
    if (entry !== null) entry.execute()
  }
}
