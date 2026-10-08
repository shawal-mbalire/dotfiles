// CONTRACT — BatteryPort (all members read-only, see AudioPort for why)
//   bool   present   a laptop battery exists
//   int    level     0-100
//   bool   charging
//   string state     "Charging"|"Discharging"|"Full"|"Plugged in"|"Unknown"
//   string timeText  "1h 5m to full" / "40m left"; "" when unknown
import QtQml

QtObject {
  property bool present: false
  property int level: 0
  property bool charging: false
  property string state: "Unknown"
  property string timeText: ""

  default property list<QtObject> resources
}
