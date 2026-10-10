// Announces Bluetooth device and Wi-Fi connects and disconnects as notifications.
// Pure diffing lives in models/ConnectionModel.qml; this only wires the ports.
import QtQml
import "../ports"
import "../models"

QtObject {
  id: root

  required property BluetoothPort bluetoothPort
  required property NetworkPort networkPort
  required property NotificationFeedPort feedPort

  // Plain values, set once at startup and then only by the handlers below.
  // A binding here would track the live state and never report a change.
  property var bluetoothSnapshot: null
  property var networkSnapshot: null

  Component.onCompleted: {
    bluetoothSnapshot = bluetoothConnected()
    networkSnapshot = networkConnected()
  }

  function bluetoothConnected() {
    return bluetoothPort.devices
      .filter(device => device.connected)
      .map(device => ({ key: device.address, label: device.name }))
  }

  function networkConnected() {
    return networkPort.connected ? [{ key: networkPort.ssid, label: networkPort.ssid }] : []
  }

  function announce(appName, changes) {
    changes.forEach(change => {
      const notice = ConnectionModel.noticeFor(appName, change)
      feedPort.post(notice.appName, notice.summary, notice.body)
    })
  }

  property Connections bluetoothWatch: Connections {
    target: root.bluetoothPort
    function onDevicesChanged() {
      const next = root.bluetoothConnected()
      root.announce("Bluetooth", ConnectionModel.transitions(root.bluetoothSnapshot, next))
      root.bluetoothSnapshot = next
    }
  }

  property Connections networkWatch: Connections {
    target: root.networkPort
    function onSsidChanged() {
      const next = root.networkConnected()
      root.announce("Network", ConnectionModel.transitions(root.networkSnapshot, next))
      root.networkSnapshot = next
    }
  }
}
