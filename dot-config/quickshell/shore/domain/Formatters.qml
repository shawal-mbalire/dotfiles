pragma Singleton

import QtQuick
import Quickshell

// Domain: pure presentation logic. Same input -> same output, no I/O, no
// system access. Unit-testable in isolation.
Singleton {
    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function clamp01(value) {
        return clamp(value, 0, 1);
    }

    // 0..1 -> integer percent (signal, volume, battery).
    function percent(value) {
        return Math.round(clamp01(value) * 100);
    }

    // ── Backlight raw <-> percent mapping ────────────────────────────────
    function rawToPercent(raw, minRaw, maxRaw) {
        if (maxRaw <= minRaw) return 0;
        return Math.round(clamp((raw - minRaw) / (maxRaw - minRaw), 0, 1) * 100);
    }

    function percentToRaw(value, minRaw, maxRaw) {
        return Math.round(minRaw + clamp(value, 0, 100) / 100 * (maxRaw - minRaw));
    }

    // ── Wi-Fi ────────────────────────────────────────────────────────────
    function isOpenNetwork(securityValue, openValue, unknownValue) {
        return securityValue === openValue || securityValue === unknownValue;
    }

    function sortWifiNetworks(networks) {
        return networks.slice().sort((a, b) =>
            (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
    }

    // ── Bluetooth ────────────────────────────────────────────────────────
    function isPaired(device) {
        return device.paired || device.bonded;
    }

    function sortBluetoothDevices(devices) {
        return devices.slice().sort((a, b) =>
            (b.connected - a.connected)
            || (isPaired(b) - isPaired(a))
            || String(btName(a)).localeCompare(String(btName(b))));
    }

    function btName(device) {
        return device.name || device.deviceName || device.address || "";
    }

    // ── Displays ─────────────────────────────────────────────────────────
    function monitorDetail(monitor) {
        if (monitor.disabled === true) return "disabled";
        return monitor.width + "×" + monitor.height + "@" + Math.round(monitor.refreshRate) + "Hz";
    }

    function isMirroring(monitor) {
        const value = String(monitor.mirrorOf || "none");
        return value !== "none" && value !== "";
    }

    // ── Media ────────────────────────────────────────────────────────────
    function trackLabel(player) {
        if (!player) return "";
        const artist = player.trackArtist || "";
        const title = player.trackTitle || "";
        return artist !== "" ? artist : title;
    }
}
