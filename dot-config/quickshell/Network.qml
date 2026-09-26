import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(network => network.connected) : null

  readonly property real signal: active ? active.signalStrength : 0

  readonly property string icon: {
    if (!Networking.wifiEnabled) return String.fromCodePoint(0xf05aa)
    if (!active) return String.fromCodePoint(0xf092d)
    let tier = signal >= 0.75 ? 4
              :signal >= 0.50 ? 3
              :signal >= 0.25 ? 2
              : 1
    return String.fromCodePoint(0xf091f + (tier-1)*3)
  }

  Text {
    text: root.icon
    color: Networking.wifiEnabled ? colorPink : colorOverlay0
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
  }
  Text {
    text: {
      if (!Networking.wifiEnabled) return "off"
      if (!root.active) return "Disconnected"
      return root.active.name
    }
    color: Networking.wifiEnabled ? colorPink : colorOverlay0
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
  }
}
