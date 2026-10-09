// CONTRACT — BluetoothPort
//   bool   available       an adapter exists                    (read-only)
//   bool   enabled         adapter powered                      (read-only)
//   string connectedName   first connected device, "" if none   (read-only)
//   var    devices         known devices, each                  (read-only)
//                            { name, address, connected }
//                          ordered as BlueZ reports them.
//   setEnabled(bool enabled)
//     Post: enabled == value once BlueZ reports back; logged no-op when !available.
//   forgetDevice(string address)
//     Pre:  address is an entry of `devices`.
//     Post: the device is unpaired/removed once BlueZ confirms.
//           No-op when !available or the address is unknown.
import QtQml

QtObject {
  property bool available: false
  property bool enabled: false
  property string connectedName: ""
  property var devices: []

  default property list<QtObject> resources

  function setEnabled(value) {}
  function forgetDevice(address) {}
}
