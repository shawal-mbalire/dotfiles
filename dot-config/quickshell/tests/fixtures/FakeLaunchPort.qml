import QtQml
import "../../domain/ports"
import "apps.js" as Apps

LaunchPort {
  property var launched: []
  apps: Apps.SAMPLE
  function launch(id) {
    if (!apps.some(a => a.id === id)) return false
    launched = launched.concat([id])
    return true
  }
}
