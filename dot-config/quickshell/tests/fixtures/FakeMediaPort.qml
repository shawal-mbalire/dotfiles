// In-memory MediaPort for tests and for running views without a player.
import QtQml
import "../../domain/ports"

MediaPort {
  available: true
  playing: true
  playerName: "Fake Player"
  title: "Test Track"
  artist: "Test Artist"
  canNext: true
  canPrevious: true
  canSeek: true
  position: 30
  length: 120

  function togglePlaying() { playing = !playing }
  function next() { position = 0 }
  function previous() { position = 0 }
  function seekTo(seconds) { position = Math.max(0, Math.min(length, seconds)) }
}
