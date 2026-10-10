// BluetoothPort over Quickshell.Bluetooth (BlueZ D-Bus). Event driven: this
// replaces the bluetoothctl polling loops that ran every 3-5 seconds.
import QtQml
import Quickshell.Bluetooth
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

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
        connected: device.connected,
        state: stateName(device.state)
      }))
    : []

  // Postcondition: BlueZ reports one of the four known connection states.
  function stateName(state) {
    if (state === BluetoothDeviceState.Connected) return "Connected"
    if (state === BluetoothDeviceState.Connecting) return "Connecting"
    if (state === BluetoothDeviceState.Disconnecting) return "Disconnecting"
    if (state === BluetoothDeviceState.Disconnected) return "Disconnected"
    Errors.postcondition(false, "bluetooth.unknown-state", "BlueZ reported an unknown device state",
                         { state: state })
    return ""
  }

  function findDevice(address) {
    return adapter.devices.values.find(d => d.address === address) ?? null
  }

  // Pre: value is a boolean.
  function setEnabled(value) {
    Errors.precondition(Contracts.isBool(value), "bluetooth.enabled-type",
                        "enabled must be a boolean", { value: value })
    if (!available) {
      console.warn("[bluetooth] setEnabled ignored: no bluetooth adapter")
      return
    }
    adapter.enabled = value
  }

  // Pre: address is a non-empty string.
  function connectDevice(address) {
    Errors.precondition(Contracts.isNonEmptyString(address), "bluetooth.address-empty",
                        "address must be a non-empty string", { address: address })
    const device = available ? findDevice(address) : null
    if (device === null) {
      console.warn("[bluetooth] connect ignored: unknown device or no adapter", address)
      return
    }
    device.connect()
  }

  // Pre: address is a non-empty string.
  function disconnectDevice(address) {
    Errors.precondition(Contracts.isNonEmptyString(address), "bluetooth.address-empty",
                        "address must be a non-empty string", { address: address })
    const device = available ? findDevice(address) : null
    if (device === null) {
      console.warn("[bluetooth] disconnect ignored: unknown device or no adapter", address)
      return
    }
    device.disconnect()
  }

  // Pre: address is a non-empty string.
  function forgetDevice(address) {
    Errors.precondition(Contracts.isNonEmptyString(address), "bluetooth.address-empty",
                        "address must be a non-empty string", { address: address })
    if (!available) return
    const device = findDevice(address)
    if (device) device.forget()
    else console.warn("[bluetooth] forget ignored: unknown device", address)
  }
}
