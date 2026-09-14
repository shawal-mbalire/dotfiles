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

    // ── Battery ──────────────────────────────────────────────────────────
    // Pure: the single alert a battery state warrants, if any.
    // Duplicate suppression / state re-arming is the caller's concern.
    function batteryAlert(capacity, charging) {
        if (charging) {
            if (capacity >= Constants.batteryAlertFull)
                return alert("100c", "Battery Full", capacity + "% — fully charged", "normal");
            if (capacity >= Constants.batteryAlertHigh)
                return alert("80c", "Battery", capacity + "% — nearing full", "normal");
            if (capacity <= Constants.batteryAlertWarn)
                return alert("20c", "Battery", capacity + "% — still low", "normal");
            return null;
        }
        if (capacity <= Constants.batteryAlertCritical)
            return alert("3p", "Critically Low Battery", capacity + "% — plug in now!", "critical");
        if (capacity <= Constants.batteryAlertLow)
            return alert("10p", "Low Battery", capacity + "% remaining", "normal");
        if (capacity <= Constants.batteryAlertWarn)
            return alert("20p", "Battery", capacity + "% remaining", "normal");
        return null;
    }

    function alert(marker, summary, body, urgency) {
        return { marker: marker, summary: summary, body: body, urgency: urgency };
    }

    // ── Clipboard ────────────────────────────────────────────────────────
    function clipLabel(line) {
        if (!line) return "";
        const tab = line.indexOf("\t");
        return tab === -1 ? line : line.substring(tab + 1);
    }

    // ── Media ────────────────────────────────────────────────────────────
    function trackLabel(player) {
        if (!player) return "";
        const artist = player.trackArtist || "";
        const title = player.trackTitle || "";
        return artist !== "" ? artist : title;
    }
}
