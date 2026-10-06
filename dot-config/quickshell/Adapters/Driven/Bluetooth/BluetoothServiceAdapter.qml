// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Bluetooth/Bluetooth
// Adapters/Driven/Bluetooth/BluetoothServiceAdapter.qml
// Driven adapter: BluetoothPort ← BlueZ via Quickshell.Bluetooth.
// Replaces the previous bluetoothctl shell-outs (Bar + ControlCenter).
import Quickshell.Bluetooth
import "../../../Domain/Ports"

BluetoothPort {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connectedDevice: {
    if (Bluetooth.devices === null) return null
    return Bluetooth.devices.values.find(d => d.connected) ?? null
  }

  available: adapter !== null
  enabled: adapter !== null && adapter.enabled
  connected: connectedDevice !== null
  deviceName: {
    if (connectedDevice === null) return ""
    return connectedDevice.name !== "" ? connectedDevice.name : connectedDevice.deviceName
  }

  function setEnabled(value) {
    if (adapter === null) return
    adapter.enabled = value
  }
}
