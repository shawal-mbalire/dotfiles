// CONTRACT — NetworkPort (Wi-Fi)
//   bool   wifiEnabled   radio on                                (read-only)
//   bool   connected                                             (read-only)
//   string ssid          active network, "" when disconnected    (read-only)
//   real   strength      0.0-1.0 of the active network           (read-only)
//   bool   scanning                                              (read-only)
//   list<WifiEntry> networks   strongest first, unique by name   (read-only)
//     WifiEntry = { name, signal: 0-100, secured, known, connected }
//   signal connectionFailed(string name, string reason)
//     reason is "NoSecrets" when a password is needed, otherwise a description.
//   setWifiEnabled(bool)        Post: wifiEnabled follows once the backend reports.
//   setScanning(bool)           Post: `networks` is kept live while true. Callers
//                               must set it back to false when they stop showing it.
//   connectTo(string name)
//     Pre:  name is a non-empty string (ValidationError otherwise). An unknown
//           name is an expected outcome: exactly one connectionFailed.
//     Post: connected/ssid follow on success, else exactly one connectionFailed(name, …).
//   connectWithPsk(string name, string psk)
//     Pre:  as connectTo, psk non-empty. Post: as connectTo.
//   Invariant: `networks` has unique names, connected entry first, then by signal.
import QtQml

QtObject {
  property bool wifiEnabled: false
  property bool connected: false
  property string ssid: ""
  property real strength: 0
  property bool scanning: false
  property var networks: []

  signal connectionFailed(string name, string reason)

  default property list<QtObject> resources

  function setWifiEnabled(value) {}
  function setScanning(value) {}
  function connectTo(name) {}
  function connectWithPsk(name, psk) {}
}
