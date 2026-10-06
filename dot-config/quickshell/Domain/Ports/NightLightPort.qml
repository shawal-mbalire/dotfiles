// Domain/Ports/NightLightPort.qml
// CONTRACT — NightLightPort
//   bool   active      colour-temperature shift is running
//   function setActive(bool)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property bool active: false

  function setActive(value) {}
}
