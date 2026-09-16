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

    function sortBluetoothDevices(devices, cache) {
        return devices.slice().sort((a, b) =>
            (b.connected - a.connected)
            || (isPaired(b) - isPaired(a))
            || String(btName(a, cache)).localeCompare(String(btName(b, cache))));
    }

    function _isMacAddress(str) {
        return !!str && !!str.match(/^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/);
    }

    function _realName(device, cache) {
        if (device.name && !_isMacAddress(device.name)) return device.name;
        const c = cache || {};
        if (c[device.address]) return c[device.address];
        return "";
    }

    function hasBtName(device, cache) {
        return !!_realName(device, cache);
    }

    function btName(device, cache) {
        return _realName(device, cache);
    }

    // ── Displays ─────────────────────────────────────────────────────────
    function monitorDetail(monitor) {
        if (monitor.disabled === true) return "disabled";
        return monitor.width + "\u00D7" + monitor.height + "@" + Math.round(monitor.refreshRate) + "Hz";
    }

    function isMirroring(monitor) {
        const value = String(monitor.mirrorOf || "none");
        return value !== "none" && value !== "";
    }

    // ── Battery ──────────────────────────────────────────────────────────
    // Pure: the single alert a battery state warrants, if any.
    // Only discharging warrants an alert — while charging we stay quiet
    // (plugged-in laptop users don't need "full"/"nearly full" popups).
    // Duplicate suppression / state re-arming is the caller's concern.
    function batteryAlert(capacity, charging) {
        if (charging) return null;
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

    // ── Wallpaper accent colour picking ──────────────────────────────────
    // Pure functions used by WallpaperColors adapter. The fallback colour
    // is injected so the domain never imports Theme.
    function normalizeAccent(c) {
        if (c.hsvValue < 0.55) return Qt.lighter(c, 1.6);
        return c;
    }

    function pickAccent(colors, fallback) {
        let best = fallback;
        if (!colors || colors.length === 0) return best;
        let bestScore = -1;
        for (const c of colors) {
            const sat = c.hsvSaturation;
            const val = c.hsvValue;
            if (val < 0.3 || val > 0.95) continue;
            const score = sat * (1 - Math.abs(val - 0.65));
            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }
        return best;
    }
}
