import "../Shared"
import "../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  required property BluetoothPort bluetoothPort

  readonly property bool powered: bluetoothPort.enabled
  readonly property bool connected: bluetoothPort.connectedName !== ""

  visible: bluetoothPort.available

  readonly property string icon: {
    if (!powered) return String.fromCodePoint(0xF00B2)
    if (connected) return String.fromCodePoint(0xF00B1)
    return String.fromCodePoint(0xF00AF)
  }

  Text {
    text: root.icon
    color: root.powered ? Theme.blue : Theme.overlay0
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  Text {
    text: !root.powered ? "off" : root.connected ? root.bluetoothPort.connectedName : "on"
    color: root.powered ? Theme.blue : Theme.overlay0
    font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
    elide: Text.ElideRight
    Layout.maximumWidth: 140
  }

  // Click toggles power. The adapter reflects BlueZ state, so no optimistic
  // flip or follow-up poll is needed.
  TapHandler {
    cursorShape: Qt.PointingHandCursor
    onTapped: root.bluetoothPort.setEnabled(!root.powered)
  }
}
