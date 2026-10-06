pragma Singleton
import QtQml

// Domain/Constants/Indicators.qml
// Pure presentation policy: map a domain value to a Nerd Font glyph, and for the
// battery a semantic tone. No Quickshell and no Theme — views pick the colour
// role from the returned tone, so this stays a pure transform.
QtObject {
  // --- Battery ---
  // Glyphs live in the Nerd Font private-use area.
  readonly property int batteryCharging: 0xF0084
  readonly property int batteryFull: 0xF0079
  readonly property int batteryEmpty: 0xF0083
  readonly property int batterySteps: 0xF007A

  // Battery colour thresholds (%) — consumed by batteryTone().
  readonly property int batteryCritical: 15
  readonly property int batteryLow: 30

  // --- Level glyph thresholds (brightness/volume) ---
  readonly property int levelOff: 0
  readonly property int levelLow: 34
  readonly property int levelHigh: 67

  // --- Wi-Fi signal buckets (0.0-1.0) ---
  readonly property real signalStrong: 0.75
  readonly property real signalGood: 0.5
  readonly property real signalWeak: 0.25

  // --- Bluetooth ---
  readonly property int bluetoothOff: 0xF00B2
  readonly property int bluetoothOn: 0xF00AF
  readonly property int bluetoothConnected: 0xF00B1

  // --- Static feature glyphs ---
  readonly property string nightLight: String.fromCodePoint(0xF0594)
  readonly property string darkMode: String.fromCodePoint(0xF0594)
  readonly property string lightMode: String.fromCodePoint(0xF0599)
  readonly property string powerProfile: String.fromCodePoint(0xF04C5)

  // A charging battery always shows the charging glyph, regardless of level.
  function iconForBattery(level, charging) {
    if (charging) return String.fromCodePoint(batteryCharging)
    if (level >= 100) return String.fromCodePoint(batteryFull)
    if (level < 10) return String.fromCodePoint(batteryEmpty)
    return String.fromCodePoint(batterySteps + (Math.floor(level / 10) - 1))
  }

  // "charging" | "critical" | "low" | "normal" — the view maps this to a Theme role.
  function batteryTone(level, charging) {
    if (charging) return "charging"
    if (level <= batteryCritical) return "critical"
    if (level <= batteryLow) return "low"
    return "normal"
  }

  function iconForBrightness(level) {
    if (level <= levelOff) return String.fromCodePoint(0xF00DA)
    if (level < levelLow) return String.fromCodePoint(0xF00DC)
    if (level < levelHigh) return String.fromCodePoint(0xF00DE)
    return String.fromCodePoint(0xF00E0)
  }

  function iconForVolume(volume, muted, ready) {
    if (!ready) return String.fromCodePoint(0xF0581)
    if (muted) return String.fromCodePoint(0xF075F)
    if (volume <= levelOff) return String.fromCodePoint(0xF0581)
    if (volume < levelLow) return String.fromCodePoint(0xF057F)
    if (volume < levelHigh) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }

  // 1 (weak) .. 4 (strong). Shares the signal buckets above.
  function signalTier(signal) {
    if (signal >= signalStrong) return 4
    if (signal >= signalGood) return 3
    if (signal >= signalWeak) return 2
    return 1
  }

  function iconForWifi(signal, wifiEnabled, connected) {
    if (!wifiEnabled) return String.fromCodePoint(0xF05AA)
    if (!connected) return String.fromCodePoint(0xF092D)
    return String.fromCodePoint(0xF091F + (signalTier(signal) - 1) * 3)
  }

  function iconForBluetooth(enabled, connected) {
    if (!enabled) return String.fromCodePoint(bluetoothOff)
    if (connected) return String.fromCodePoint(bluetoothConnected)
    return String.fromCodePoint(bluetoothOn)
  }

  function iconForDarkMode(dark) {
    return dark ? darkMode : lightMode
  }
}
