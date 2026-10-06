// Domain/Ports/BluetoothPort.qml
// CONTRACT — BluetoothPort
//   bool   available     a bluetooth adapter exists
//   bool   enabled       adapter powered on
//   bool   connected     a device is connected
//   string deviceName    connected device name, "" when none
//   function setEnabled(bool)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property bool available: false
  property bool enabled: false
  property bool connected: false
  property string deviceName: ""

  function setEnabled(value) {}
}
