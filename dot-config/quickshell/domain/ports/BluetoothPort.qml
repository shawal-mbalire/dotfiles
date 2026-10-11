// CONTRACT — BluetoothPort
//   bool   available       an adapter exists                    (read-only)
//   bool   enabled         adapter powered                      (read-only)
//   string connectedName   first connected device, "" if none   (read-only)
//   bool   discovering    adapter is scanning for nearby devices (read-only)
//   var    devices         known and nearby devices, each        (read-only)
//                            { name, address, paired, connected, state }
//                          state is "Connected"|"Connecting"|"Disconnecting"|"Disconnected".
//                          ordered as BlueZ reports them.
//   setEnabled(bool enabled)
//     Pre:  enabled is a boolean (ValidationError otherwise).
//     Post: enabled == value once BlueZ reports back; logged no-op when !available.
//   setDiscovering(bool scanning)
//     Pre:  scanning is a boolean (ValidationError otherwise).
//     Post: discovering == value once BlueZ reports back; `devices` includes nearby
//           devices while true. Logged no-op when !available or !enabled.
//   connectDevice(string address)
//     Pre:  address is a non-empty string (ValidationError otherwise).
//     Post: an unpaired device is paired first. State moves to "Connecting" and then
//           "Connected" once BlueZ confirms. Logged no-op when !available or the address is unknown.
//   disconnectDevice(string address)
//     Pre:  address is a non-empty string (ValidationError otherwise).
//     Post: state moves to "Disconnecting" and then "Disconnected". Logged no-op when unknown.
//   forgetDevice(string address)
//     Pre:  address is a non-empty string (ValidationError otherwise).
//     Post: the device is unpaired/removed once BlueZ confirms.
//           Logged no-op when !available or the address is unknown.
//   Invariant: an unrecognised BlueZ state is a ContractViolation, never a default.
import QtQml

QtObject {
  property bool available: false
  property bool enabled: false
  property string connectedName: ""
  property bool discovering: false
  property var devices: []

  default property list<QtObject> resources

  function setEnabled(value) {}
  function setDiscovering(value) {}
  function connectDevice(address) {}
  function disconnectDevice(address) {}
  function forgetDevice(address) {}
}
