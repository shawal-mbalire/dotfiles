// LaunchPort over Quickshell's DesktopEntries index, which parses .desktop
// files natively and updates when they change. Replaces the find/awk scan
// and the hand-written Exec tokenizer.
import QtQml
import Quickshell
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

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
      icon: e.icon
    }))
    .sort((a, b) => a.name.localeCompare(b.name))

  // Pre: id is a non-empty string. An unknown id is an expected outcome: false.
  function launch(id) {
    Errors.precondition(Contracts.isNonEmptyString(id), "launch.id-empty",
                        "desktop entry id must be a non-empty string", { id: id })
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
