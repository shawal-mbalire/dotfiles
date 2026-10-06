// Domain/Ports/NetworkPort.qml
// CONTRACT — NetworkPort
//   bool   available
//   bool   wifiEnabled
//   bool   connected
//   string activeName
//   real   signal        0.0-1.0
//   bool   scanning
//   var    networks      [{ name, signal, secured, known, connected }]
//   function setWifiEnabled(bool)
//   function scan()
//   function connectTo(string name)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property bool available: false
  property bool wifiEnabled: false
  property bool connected: false
  property string activeName: ""
  property real signal: 0
  property bool scanning: false
  property var networks: []

  function setWifiEnabled(value) {}
  function scan() {}
  function connectTo(name) {}
}
