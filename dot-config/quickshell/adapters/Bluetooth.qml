pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
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

    property var nameCache: ({})

    readonly property var devices: root.adapter
        ? Formatters.sortBluetoothDevices(
            root.adapter.devices.values.filter(d => Formatters.hasBtName(d, root.nameCache)),
            root.nameCache)
        : []
    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    readonly property var pairedDevices: root.devices.filter(
        d => d.connected || Formatters.isPaired(d))
    readonly property var otherDevices: root.devices.filter(
        d => !(d.connected || Formatters.isPaired(d)))
    readonly property int connectedCount: root.connectedDevices.length

    Component.onCompleted: refreshNameCache()

    onDiscoveringChanged: refreshNameCache()

    function refreshNameCache() {
        if (!nameLookupProc.running) nameLookupProc.running = true;
    }

    Process {
        id: nameLookupProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const text = out.text.trim();
                if (text === "") { root.nameCache = {}; return; }
                const cache = {};
                for (const line of text.split("\n")) {
                    const parts = line.split(/\s+/);
                    if (parts.length < 3 || parts[0] !== "Device") continue;
                    const mac = parts[1];
                    const alias = parts.slice(2).join(" ");
                    if (alias && !alias.match(/^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/))
                        cache[mac] = alias;
                }
                root.nameCache = cache;
            }
        }
    }

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
