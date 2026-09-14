pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../domain"

// Driven adapter: Bluetooth (BluetoothPort) over Quickshell's native backend.
// Devices stay reactive service handles (that is the QML idiom); every action
// goes through a method here so the UI never imports Quickshell.Bluetooth.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter ? root.adapter.enabled : false
    readonly property bool discovering: root.adapter ? root.adapter.discovering : false
    readonly property string name: root.adapter ? root.adapter.name : ""

    readonly property var devices: root.adapter
        ? Formatters.sortBluetoothDevices(root.adapter.devices.values)
        : []
    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    readonly property var pairedDevices: root.devices.filter(
        d => d.connected || Formatters.isPaired(d))
    readonly property var otherDevices: root.devices.filter(
        d => !(d.connected || Formatters.isPaired(d)))
    readonly property int connectedCount: root.connectedDevices.length

    // ── BluetoothPort ─────────────────────────────────────────────────────
    function setEnabled(value) {
        if (root.adapter) root.adapter.enabled = value;
    }

    function toggle() {
        if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
    }

    function setDiscovering(value) {
        if (root.adapter) root.adapter.discovering = value;
    }

    function toggleDiscovering() {
        if (root.adapter) root.adapter.discovering = !root.adapter.discovering;
    }

    function connectDevice(device) {
        if (device) device.connect();
    }

    function disconnectDevice(device) {
        if (device) device.disconnect();
    }

    function pairDevice(device) {
        if (device) device.pair();
    }

    function forgetDevice(device) {
        if (device) device.forget();
    }
}
