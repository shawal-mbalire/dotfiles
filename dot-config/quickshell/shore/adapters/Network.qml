pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Network status via Quickshell's native NetworkManager backend.
// No polling, no subprocess.
Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardware: Networking.wifiHardwareEnabled

    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi) return devices[i];
        return null;
    }

    readonly property var wiredDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wired) return devices[i];
        return null;
    }

    readonly property var connectedWifi: {
        if (!wifiDevice) return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i];
        return null;
    }

    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected
    readonly property bool wireless: connectedWifi !== null
    readonly property bool connected: wiredConnected || wireless

    // SSID when on wifi, otherwise the wired interface / fallback.
    readonly property string label: {
        if (connectedWifi) return connectedWifi.name;
        if (wiredConnected) return wiredDevice.name;
        return "";
    }

    readonly property real signal: connectedWifi ? connectedWifi.signalStrength : 0

    function setWifi(enabled) {
        Networking.wifiEnabled = enabled;
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
