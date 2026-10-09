// NetworkPort over Quickshell.Networking (NetworkManager D-Bus). Replaces the
// nmcli list/connect/radio processes; the scan list is live while scanning.
import QtQml
import Quickshell.Networking
import "../../domain/ports"

NetworkPort {
  id: root

  readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var active: device ? device.networks.values.find(n => n.connected) ?? null : null
  property var attempt: null

  wifiEnabled: Networking.wifiEnabled
  connected: active !== null
  ssid: active ? active.name : ""
  strength: active ? active.signalStrength : 0
  scanning: device !== null && device.scannerEnabled
  networks: device ? toEntries(device.networks.values) : []

  // DTO boundary: vendor objects become plain values, strongest per SSID.
  function toEntries(list) {
    const best = {}
    for (const n of Array.from(list)) {
      if (!n.name) continue
      const prev = best[n.name]
      if (!prev || n.connected || (!prev.connected && n.signalStrength > prev.signalStrength)) best[n.name] = n
    }
    return Object.values(best)
      .map(n => ({
        name: n.name,
        signal: Math.round(n.signalStrength * 100),
        secured: n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe,
        known: n.known,
        connected: n.connected
      }))
      .sort((a, b) => (b.connected - a.connected) || (b.signal - a.signal))
  }

  function find(name) {
    if (!device) return null
    let match = null
    for (const n of Array.from(device.networks.values)) {
      if (n.name === name && (!match || n.signalStrength > match.signalStrength)) match = n
    }
    return match
  }

  function setWifiEnabled(value) {
    Networking.wifiEnabled = value
  }

  function setScanning(value) {
    if (device) device.scannerEnabled = value
  }

  function connectTo(name) {
    const n = find(name)
    if (!n) {
      connectionFailed(name, "Network not found")
      return
    }
    attempt = n
    n.connect()
  }

  function connectWithPsk(name, psk) {
    const n = find(name)
    if (!n) {
      connectionFailed(name, "Network not found")
      return
    }
    attempt = n
    n.connectWithPsk(psk)
  }

  Connections {
    target: root.attempt
    function onConnectionFailed(reason) {
      const name = root.attempt.name
      const text = reason === ConnectionFailReason.NoSecrets ? "NoSecrets" : ConnectionFailReason.toString(reason)
      console.warn("[network] connection to", name, "failed:", text)
      root.connectionFailed(name, text)
    }
  }
}
