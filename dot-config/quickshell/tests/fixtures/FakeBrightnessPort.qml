import QtQml
import "../../domain/ports"

BrightnessPort {
  available: true
  percent: 70
  function setPercent(value) { percent = Math.max(0, Math.min(100, Math.round(value))) }
}
