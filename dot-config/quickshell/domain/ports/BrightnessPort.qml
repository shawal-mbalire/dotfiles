// CONTRACT — BrightnessPort (backlight)
//   bool available   a backlight device was found               (read-only)
//   int  percent     0-100                                      (read-only)
//   setPercent(int percent)
//     Pre:  percent is finite.
//     Post: percent == clamp(round(percent), 0, 100) immediately (optimistic) and
//           after the device confirms. Rapid calls coalesce; the last one wins.
import QtQml

QtObject {
  property bool available: false
  property int percent: 0

  default property list<QtObject> resources

  function setPercent(value) {}
}
