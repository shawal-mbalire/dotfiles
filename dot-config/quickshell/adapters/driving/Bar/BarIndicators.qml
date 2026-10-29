import "../../../infra/config"
import "../../../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 20

  required property ColorCorrectionPort colorCorrectionPort
  required property NetworkPort networkPort
  required property BluetoothPort bluetoothPort
  required property AudioPort audioPort
  required property BrightnessPort brightnessPort
  required property BatteryPort batteryPort

  property int audioScrollStep: 5
  property int audioScrollMax: 100
  property int brightnessScrollStep: 5

  // ── Color Correction ──────────────────────────────────────────────────────
  RowLayout {
    spacing: 6
    readonly property bool active: root.colorCorrectionPort.active
    Text {
      text: String.fromCodePoint(0xF0594)
      color: parent.active ? Theme.peach : Theme.overlay0
      font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
    }
    TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.colorCorrectionPort.setActive(!parent.active) }
  }

  // ── Network ───────────────────────────────────────────────────────────────
  RowLayout {
    spacing: 6
    readonly property bool wifiEnabled: root.networkPort.wifiEnabled
    readonly property real strength: root.networkPort.strength
    readonly property string icon: !wifiEnabled ? String.fromCodePoint(0xF05AA) : !root.networkPort.connected ? String.fromCodePoint(0xF092D)
      : String.fromCodePoint(0xF091F + ((strength >= 0.75 ? 4 : strength >= 0.50 ? 3 : strength >= 0.25 ? 2 : 1) - 1) * 3)

    Text { text: parent.icon; color: parent.wifiEnabled ? Theme.pink : Theme.overlay0; font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    Text {
      text: !parent.wifiEnabled ? "off" : root.networkPort.connected ? root.networkPort.ssid : "Disconnected"
      color: parent.wifiEnabled ? Theme.pink : Theme.overlay0; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }; elide: Text.ElideRight; Layout.maximumWidth: 160
    }
  }

  // ── Bluetooth ─────────────────────────────────────────────────────────────
  RowLayout {
    spacing: 6
    readonly property bool powered: root.bluetoothPort.enabled
    readonly property bool connected: root.bluetoothPort.connectedName !== ""
    visible: root.bluetoothPort.available
    readonly property string icon: !powered ? String.fromCodePoint(0xF00B2) : connected ? String.fromCodePoint(0xF00B1) : String.fromCodePoint(0xF00AF)

    Text { text: parent.icon; color: parent.powered ? Theme.blue : Theme.overlay0; font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    Text { text: !parent.powered ? "off" : parent.connected ? root.bluetoothPort.connectedName : "on"; color: parent.powered ? Theme.blue : Theme.overlay0; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }; elide: Text.ElideRight; Layout.maximumWidth: 140 }
    TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.bluetoothPort.setEnabled(!parent.powered) }
  }

  // ── Volume ────────────────────────────────────────────────────────────────
  RowLayout {
    spacing: 7
    readonly property bool ready: root.audioPort.ready
    readonly property bool muted: root.audioPort.muted
    readonly property int volume: root.audioPort.volume
    readonly property string icon: !ready || volume === 0 ? String.fromCodePoint(0xF0581) : muted ? String.fromCodePoint(0xF075F) : volume < 34 ? String.fromCodePoint(0xF057F) : volume < 67 ? String.fromCodePoint(0xF0580) : String.fromCodePoint(0xF057E)

    Text { text: parent.icon; color: parent.muted ? Theme.overlay1 : Theme.yellow; font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    Text { text: !parent.ready ? "_" : parent.muted ? "Muted" : parent.volume + "%"; color: parent.muted ? Theme.overlay1 : Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    TapHandler { cursorShape: Qt.PointingHandCursor; onTapped: root.audioPort.setMuted(!parent.muted) }
    WheelHandler {
      onWheel: ev => {
        const step = ev.angleDelta.y > 0 ? root.audioScrollStep : -root.audioScrollStep
        root.audioPort.setVolume(Math.max(0, Math.min(Math.max(root.audioScrollMax, parent.volume), parent.volume + step)))
      }
    }
  }

  // ── Brightness ────────────────────────────────────────────────────────────
  RowLayout {
    spacing: 7
    readonly property int level: root.brightnessPort.percent
    visible: root.brightnessPort.available
    readonly property string icon: level === 0 ? String.fromCodePoint(0xF00DA) : level < 34 ? String.fromCodePoint(0xF00DC) : level < 67 ? String.fromCodePoint(0xF00DE) : String.fromCodePoint(0xF00E0)

    Text { text: parent.icon; color: parent.level === 0 ? Theme.overlay0 : Theme.yellow; font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    Text { text: parent.level + "%"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight } }
    WheelHandler {
      onWheel: ev => {
        const step = ev.angleDelta.y > 0 ? root.brightnessScrollStep : -root.brightnessScrollStep
        root.brightnessPort.setPercent(Math.max(0, Math.min(100, parent.level + step)))
      }
    }
  }

  // ── Battery ───────────────────────────────────────────────────────────────
  RowLayout {
    spacing: 5
    readonly property int level: root.batteryPort.level
    readonly property bool charging: root.batteryPort.charging
    visible: root.batteryPort.present
    readonly property string icon: charging ? String.fromCodePoint(0xF0084) : level >= 100 ? String.fromCodePoint(0xF0079) : level < 10 ? String.fromCodePoint(0xF0083) : String.fromCodePoint(0xF007A + (Math.floor(level / 10) - 1))

    Text {
      text: parent.icon; font { family: Theme.nerdFont; pixelSize: 17; weight: Theme.fontWeight }; Layout.alignment: Qt.AlignVCenter
      color: parent.charging ? Theme.green : parent.level <= 15 ? Theme.red : parent.level <= 30 ? Theme.peach : Theme.green
    }
    Text { text: parent.level + "%"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Theme.fontWeight }; Layout.alignment: Qt.AlignVCenter }
  }
}
