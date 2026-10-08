// In-memory AudioPort for tests and for running views without a device.
import QtQml
import "../../domain/ports"

AudioPort {
  ready: true
  volume: 40
  function setVolume(percent) { volume = Math.max(0, Math.min(150, Math.round(percent))) }
  function setMuted(value) { muted = value }
}
