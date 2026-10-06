// Domain/Ports/BatteryPort.qml
// CONTRACT — BatteryPort
//   bool   present    laptop battery exists
//   bool   charging
//   int    level      0-100
//   string state      "Charging"|"Discharging"|"Full"|"Plugged"|"Unknown"
//   string timeText   human remaining/until-full, "" when unknown
//
// Port properties are intentionally NOT `readonly`: an adapter subtype must bind
// them, and QML forbids overriding a `readonly` property ("Invalid property
// assignment: … is a read-only property"). Consumers simply never write them.
import QtQml

Port {
  property bool present: false
  property bool charging: false
  property int level: 0
  property string state: "Unknown"
  property string timeText: ""
}
