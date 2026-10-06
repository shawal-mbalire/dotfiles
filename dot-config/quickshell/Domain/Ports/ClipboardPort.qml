// Domain/Ports/ClipboardPort.qml
// CONTRACT — ClipboardPort
//   bool   available
//   var    history      recent text entries, newest first
//   function copy(string text)
//   function clear()
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property bool available: false
  property var history: []

  function copy(text) {}
  function clear() {}
}
