// CONTRACT — BrightnessPort (backlight)
//   bool available   a backlight device was found               (read-only)
//   int  percent     0-100                                      (read-only)
//   setPercent(int percent)
//     Pre:  percent is finite and within 0..100 (ValidationError otherwise).
//     Post: percent == round(value) immediately (optimistic) and after the device
//           confirms. Rapid calls coalesce; the last one wins. Logged no-op when !available.
//   refresh()
//     Post: the device is re-read now. Called after an external change (keybinds).
import QtQml

QtObject {
  property bool available: false
  property int percent: 0

  default property list<QtObject> resources

  function setPercent(value) {}
  function refresh() {}
}
