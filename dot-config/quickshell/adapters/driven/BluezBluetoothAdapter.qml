// BluetoothPort over Quickshell.Bluetooth (BlueZ D-Bus). Event driven: this
// replaces the bluetoothctl polling loops that ran every 3-5 seconds.
import QtQml
import Quickshell.Bluetooth
import "../../domain/ports"

BluetoothPort {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connectedDevice: Bluetooth.devices.values.find(d => d.connected) ?? null

  available: adapter !== null
  enabled: adapter !== null && adapter.enabled
  connectedName: enabled && connectedDevice !== null ? connectedDevice.name : ""
  devices: available ? adapter.devices.values
      .filter(device => device.paired || device.connected)
      .map(device => ({
        name: device.name !== "" ? device.name : device.deviceName,
        address: device.address,
        connected: device.connected
      }))
    : []

  function setEnabled(value) {
    if (!available) {
      console.warn("[bluetooth] setEnabled ignored: no bluetooth adapter")
      return
    }
    adapter.enabled = value
  }

  function forgetDevice(address) {
    if (!available) return
    const device = adapter.devices.values.find(d => d.address === address)
    if (device) device.forget()
  }
}
