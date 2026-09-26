import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 5

  property var battery: UPower.displayDevice
  property bool charging: battery.state === UPowerDeviceState.Charging
  readonly property int level: Math.round(battery.percentage * 100)

  readonly property string icon: {
    if (charging) return String.fromCodePoint(0xF0084)
    if (level >= 100) return String.fromCodePoint(0xF0079)
    if (level < 10) return String.fromCodePoint(0xF0083)
    return String.fromCodePoint(0xF007A + (Math.floor(level/10)-1))
  }

  Text {
    text: root.icon
    color: root.charging ? colorGreen
         : root.level <= 15 ? colorRed
         : root.level <= 30 ? colorPeach
         : colorGreen
    font {
      family: themeNerdFont
      pixelSize: 17
      weight: themeFontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }

  Text {
    text: root.level + "%"
    color: colorText
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }
}
