// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Networking/Networking
// Adapters/Driven/Network/NetworkServiceAdapter.qml
// Driven adapter: NetworkPort ← NetworkManager via Quickshell.Networking.
// Fully typed — no nmcli. Scanning is driven by WifiDevice.scannerEnabled.
import Quickshell.Networking
import "../../../Domain/Ports"

NetworkPort {
  id: root

  readonly property var wifiDevice: {
    if (Networking.devices === null) return null
    return Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  }

  readonly property var models: wifiDevice !== null ? wifiDevice.networks.values : []
  readonly property var activeNetwork: models.find(n => n.connected) ?? null

  available: wifiDevice !== null
  wifiEnabled: Networking.wifiEnabled
  connected: activeNetwork !== null
  activeName: activeNetwork !== null ? activeNetwork.name : ""
  signal: activeNetwork !== null ? activeNetwork.signalStrength : 0
  scanning: wifiDevice !== null && wifiDevice.scannerEnabled

  networks: models.map(n => ({
    name: n.name,
    signal: n.signalStrength,
    secured: n.security !== WifiSecurityType.Open,
    known: n.known,
    connected: n.connected
  }))

  function setWifiEnabled(value) {
    Networking.wifiEnabled = value
  }

  function scan() {
    if (wifiDevice !== null) wifiDevice.scannerEnabled = true
  }

  function connectTo(name) {
    const net = models.find(n => n.name === name)
    if (net !== undefined) net.connect()
  }
}
