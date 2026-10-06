// Domain/Ports/AudioPort.qml
// CONTRACT — AudioPort
//   bool   ready
//   bool   muted
//   int    volume      0-150
//   function setVolume(int)   0-150
//   function setMuted(bool)
//
// Properties are intentionally writable so the adapter subtype can bind them
// (see BatteryPort for why `readonly` is not used).
import QtQml

Port {
  property bool ready: false
  property bool muted: false
  property int volume: 0

  function setVolume(value) {}
  function setMuted(value) {}
}
