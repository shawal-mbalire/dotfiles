// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.UPower/
// Adapters/Driven/UPower/UPowerBatteryAdapter.qml
// Driven adapter: BatteryPort ← UPower. Translates the UPower device into
// domain values; no UPower type leaves this file.
import Quickshell.Services.UPower
import "../../../Domain/Ports"

BatteryPort {
  id: root

  readonly property var device: UPower.displayDevice

  present: device !== null && device.ready && device.isLaptopBattery
  charging: present && device.state === UPowerDeviceState.Charging
  level: present ? Math.round(device.percentage * 100) : 0

  state: {
    if (!present) return "Unknown"
    if (device.state === UPowerDeviceState.Charging) return "Charging"
    if (device.state === UPowerDeviceState.Discharging) return "Discharging"
    if (device.state === UPowerDeviceState.FullyCharged) return "Full"
    if (device.state === UPowerDeviceState.PendingCharge) return "Plugged"
    return "Unknown"
  }

  timeText: {
    if (!present) return ""
    const s = charging ? device.timeToFull : device.timeToEmpty
    if (s <= 0) return ""
    const h = Math.floor(s / 3600)
    const m = Math.round((s % 3600) / 60)
    const t = h > 0 ? h + "h " + m + "m" : m + "m"
    return charging ? t + " to full" : t + " left"
  }
}
