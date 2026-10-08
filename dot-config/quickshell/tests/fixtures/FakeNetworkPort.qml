import QtQml
import "../../domain/ports"

NetworkPort {
  property var attempts: []
  wifiEnabled: true
  connected: true
  ssid: "home"
  strength: 0.8
  networks: [
    { name: "home", signal: 80, secured: true, known: true, connected: true },
    { name: "cafe", signal: 55, secured: true, known: false, connected: false },
    { name: "open", signal: 30, secured: false, known: false, connected: false }
  ]
  function setWifiEnabled(value) { wifiEnabled = value }
  function setScanning(value) { scanning = value }
  function connectTo(name) { attempts = attempts.concat([name]); connectionFailed(name, "NoSecrets") }
  function connectWithPsk(name, psk) { attempts = attempts.concat([name + ":" + psk]) }
}
