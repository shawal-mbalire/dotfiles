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
  discovering: available && adapter.discovering
  devices: available ? adapter.devices.values
      .filter(d => d.paired || d.connected || discovering)
      .map(d => ({ name: d.name !== "" ? d.name : d.deviceName, address: d.address, paired: d.paired, connected: d.connected, state: stateName(d.state) })) : []

  function stateName(state) {
    if (state === BluetoothDeviceState.Connected) return "Connected"
    if (state === BluetoothDeviceState.Connecting) return "Connecting"
    if (state === BluetoothDeviceState.Disconnecting) return "Disconnecting"
    if (state === BluetoothDeviceState.Disconnected) return "Disconnected"
    Errors.postcondition(false, "bluetooth.unknown-state", "BlueZ reported an unknown device state", { state: state })
    return ""
  }

  function findDevice(addr) { return adapter.devices.values.find(d => d.address === addr) ?? null }

  function setEnabled(val) {
    Errors.precondition(Contracts.isBool(val), "bluetooth.enabled-type", "enabled must be a boolean", { value: val })
    if (available) adapter.enabled = val
  }

  function setDiscovering(val) {
    Errors.precondition(Contracts.isBool(val), "bluetooth.discovering-type", "discovering must be a boolean", { value: val })
    if (available && enabled) adapter.discovering = val
  }

  function connectDevice(addr) {
    Errors.precondition(Contracts.isNonEmptyString(addr), "bluetooth.address-empty", "address must be a non-empty string", { address: addr })
    const d = available ? findDevice(addr) : null
    if (d) d.paired ? d.connect() : d.pair()
  }

  function disconnectDevice(addr) {
    Errors.precondition(Contracts.isNonEmptyString(addr), "bluetooth.address-empty", "address must be a non-empty string", { address: addr })
    const d = available ? findDevice(addr) : null
    if (d) d.disconnect()
  }

  function forgetDevice(addr) {
    Errors.precondition(Contracts.isNonEmptyString(addr), "bluetooth.address-empty", "address must be a non-empty string", { address: addr })
    const d = available ? findDevice(addr) : null
    if (d) d.forget()
  }
}
