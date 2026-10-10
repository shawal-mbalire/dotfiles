pragma Singleton
import QtQml

// Static bounds named by port contracts (AGENTS §7: no magic numbers in domain).
QtObject {
  readonly property int percentMin: 0
  readonly property int percentMax: 100
  readonly property int volumeMax: 100
  readonly property int colorTemperatureMin: 1000
  readonly property int colorTemperatureMax: 25000
  // Exponent of the perceptual backlight curve (brightnessctl -e4, the Hyprland keys).
  readonly property int brightnessExponent: 4
  // Lowest raw backlight value written, so the screen never goes fully dark (brightnessctl -n2).
  readonly property int brightnessMinRaw: 2
}
