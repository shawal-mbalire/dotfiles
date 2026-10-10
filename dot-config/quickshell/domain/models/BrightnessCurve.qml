pragma Singleton
import QtQml
import "../constants"

// The perceptual brightness curve used by `brightnessctl -e<K>`:
//   raw = max * (percent / 100) ^ K     so     percent = 100 * (raw / max) ^ (1 / K)
// Keys and the shell must share it, or a readout jumps when the other one changes it.
QtObject {
  // Pre: max > 0. Post: an integer in 0..100.
  function percentOf(raw, max) {
    if (!(max > 0)) return 0
    const fraction = Math.max(0, Math.min(1, raw / max))
    return Math.round(100 * Math.pow(fraction, 1 / Bounds.brightnessExponent))
  }
}
