// BatteryPort over Quickshell.Services.UPower (display device).
import QtQml
import Quickshell.Services.UPower
import "../../../domain/ports"
import "../../../domain/models/duration.js" as Duration

BatteryPort {
  id: root

  readonly property var device: UPower.displayDevice
  readonly property bool hasDevice: device !== null

  present: hasDevice && device.ready && device.isLaptopBattery
  level: hasDevice ? Math.round(device.percentage * 100) : 0
  charging: hasDevice && device.state === UPowerDeviceState.Charging
  state: !hasDevice ? "Unknown"
       : charging ? "Charging"
       : device.state === UPowerDeviceState.Discharging ? "Discharging"
       : device.state === UPowerDeviceState.FullyCharged ? "Full"
       : device.state === UPowerDeviceState.PendingCharge ? "Plugged in"
       : "Unknown"
  timeText: {
    if (!hasDevice) return ""
    const t = Duration.humanize(charging ? device.timeToFull : device.timeToEmpty)
    if (t === "") return ""
    return charging ? t + " to full" : t + " left"
  }
}
