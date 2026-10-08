// BluetoothPort over Quickshell.Bluetooth (BlueZ D-Bus). Event driven: this
// replaces the bluetoothctl polling loops that ran every 3-5 seconds.
import QtQml
import Quickshell.Bluetooth
import "../../../domain/ports"

BluetoothPort {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null

  available: adapter !== null
  enabled: adapter !== null && adapter.enabled
  connectedName: enabled && connectedDevice !== null ? connectedDevice.name : ""

  function setEnabled(value) {
    if (!available) {
      console.warn("[bluetooth] setEnabled ignored: no bluetooth adapter")
      return
    }
    adapter.enabled = value
  }
}
