// Domain/Ports/BrightnessPort.qml
// CONTRACT — BrightnessPort
//   int    level      0-100
//   function setLevel(int)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property int level: 0

  function setLevel(value) {}
}
