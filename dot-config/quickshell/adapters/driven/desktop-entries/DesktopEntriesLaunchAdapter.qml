// LaunchPort over Quickshell's DesktopEntries index, which parses .desktop
// files natively and updates when they change. Replaces the find/awk scan
// and the hand-written Exec tokenizer.
import QtQml
import Quickshell
import "../../../domain/ports"

LaunchPort {
  id: root

  // Prefix for Terminal=true entries, e.g. ["kitty", "-e"].
  required property var terminalCommand

  apps: DesktopEntries.applications.values
    .filter(e => e.id && e.name)
    .map(e => ({
      id: e.id,
      name: e.name,
      genericName: e.genericName,
      comment: e.comment,
      keywords: Array.from(e.keywords ?? []),
      iconSource: e.icon ? Quickshell.iconPath(e.icon, true) : ""
    }))
    .sort((a, b) => a.name.localeCompare(b.name))

  function launch(id) {
    const entry = DesktopEntries.byId(id)
    if (!entry) {
      console.warn("[launcher] unknown desktop entry", id)
      return false
    }
    if (!entry.runInTerminal) {
      entry.execute()
      return true
    }
    const context = { command: root.terminalCommand.concat(entry.command) }
    if (entry.workingDirectory) context.workingDirectory = entry.workingDirectory
    Quickshell.execDetached(context)
    return true
  }
}
