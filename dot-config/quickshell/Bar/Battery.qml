import "../Shared"
import "../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 5

  required property BatteryPort batteryPort

  readonly property int level: batteryPort.level
  readonly property bool charging: batteryPort.charging

  visible: batteryPort.present

  readonly property string icon: {
    if (charging) return String.fromCodePoint(0xF0084)
    if (level >= 100) return String.fromCodePoint(0xF0079)
    if (level < 10) return String.fromCodePoint(0xF0083)
    return String.fromCodePoint(0xF007A + (Math.floor(level / 10) - 1))
  }

  Text {
    text: root.icon
    color: root.charging ? Theme.green
         : root.level <= 15 ? Theme.red
         : root.level <= 30 ? Theme.peach
         : Theme.green
    font { family: Theme.nerdFont; pixelSize: 17; weight: Theme.fontWeight }
    Layout.alignment: Qt.AlignVCenter
  }

  Text {
    text: root.level + "%"
    color: Theme.text
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
    Layout.alignment: Qt.AlignVCenter
  }
}
