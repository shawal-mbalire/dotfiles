// CONTRACT — BluetoothPort
//   bool   available       an adapter exists                    (read-only)
//   bool   enabled         adapter powered                      (read-only)
//   string connectedName   first connected device, "" if none   (read-only)
//   setEnabled(bool enabled)
//     Post: enabled == value once BlueZ reports back; logged no-op when !available.
import QtQml

QtObject {
  property bool available: false
  property bool enabled: false
  property string connectedName: ""

  default property list<QtObject> resources

  function setEnabled(value) {}
}
