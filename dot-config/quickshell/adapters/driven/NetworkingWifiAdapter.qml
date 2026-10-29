import QtQml
import Quickshell.Networking
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

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

  function toEntries(list) {
    const best = {}
    for (const n of Array.from(list)) {
      if (!n.name) continue
      Errors.postcondition(Contracts.isInRange(n.signalStrength, 0, 1), "network.signal-range", "signal strength is outside 0..1", { name: n.name, strength: n.signalStrength })
      const prev = best[n.name]
      if (!prev || n.connected || (!prev.connected && n.signalStrength > prev.signalStrength)) best[n.name] = n
    }
    return Object.values(best).map(n => ({
      name: n.name, signal: Math.round(n.signalStrength * 100),
      secured: n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe,
      known: n.known, connected: n.connected
    })).sort((a, b) => (b.connected - a.connected) || (b.signal - a.signal))
  }

  function find(name) {
    if (!device) return null
    let match = null
    for (const n of Array.from(device.networks.values)) {
      if (n.name === name && (!match || n.signalStrength > match.signalStrength)) match = n
    }
    return match
  }

  function setWifiEnabled(val) {
    Errors.precondition(Contracts.isBool(val), "network.wifi-type", "wifiEnabled must be a boolean", { value: val })
    Networking.wifiEnabled = val
  }

  function setScanning(val) {
    Errors.precondition(Contracts.isBool(val), "network.scanning-type", "scanning must be a boolean", { value: val })
    if (device) device.scannerEnabled = val
  }

  function connectTo(name) {
    Errors.precondition(Contracts.isNonEmptyString(name), "network.name-empty", "network name must be a non-empty string", { name: name })
    const n = find(name)
    if (!n) { connectionFailed(name, "Network not found"); return }
    attempt = n; n.connect()
  }

  function connectWithPsk(name, psk) {
    Errors.precondition(Contracts.isNonEmptyString(name) && Contracts.isNonEmptyString(psk), "network.psk-empty", "network name and passphrase must be non-empty", { name: name })
    const n = find(name)
    if (!n) { connectionFailed(name, "Network not found"); return }
    attempt = n; n.connectWithPsk(psk)
  }

  Connections {
    target: root.attempt
    function onConnectionFailed(reason) {
      const name = root.attempt.name, text = reason === ConnectionFailReason.NoSecrets ? "NoSecrets" : ConnectionFailReason.toString(reason)
      root.connectionFailed(name, text)
    }
  }
}
