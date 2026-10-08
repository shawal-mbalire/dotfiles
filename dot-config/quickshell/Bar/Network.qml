import "../Shared"
import "../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  required property NetworkPort networkPort

  readonly property bool wifiEnabled: networkPort.wifiEnabled
  readonly property real strength: networkPort.strength

  readonly property string icon: {
    if (!wifiEnabled) return String.fromCodePoint(0xF05AA)
    if (!networkPort.connected) return String.fromCodePoint(0xF092D)
    const tier = strength >= 0.75 ? 4
               : strength >= 0.50 ? 3
               : strength >= 0.25 ? 2
               : 1
    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }

  Text {
    text: root.icon
    color: root.wifiEnabled ? Theme.pink : Theme.overlay0
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  Text {
    text: !root.wifiEnabled ? "off" : root.networkPort.connected ? root.networkPort.ssid : "Disconnected"
    color: root.wifiEnabled ? Theme.pink : Theme.overlay0
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
    elide: Text.ElideRight
    Layout.maximumWidth: 160
  }
}
