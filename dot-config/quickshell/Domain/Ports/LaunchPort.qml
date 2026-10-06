// Domain/Ports/LaunchPort.qml
// CONTRACT — LaunchPort
//   var    applications   [{ id, name, icon, genericName, comment }]
//                         `icon` is already an Image-usable source
//   function launch(string id)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property var applications: []

  function launch(id) {}
}
