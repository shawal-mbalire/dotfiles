// MediaPort over Quickshell.Services.Mpris.
//
// D-Bus/MPRIS shapes stop at this boundary: the model of players is reduced to
// one active player and translated into the domain values MediaPort exposes.
// Player selection prefers the one currently playing, then any controllable
// player, so the shell does not flip around while several players exist.
import QtQml
import Quickshell.Services.Mpris
import "../../../domain/ports"

MediaPort {
  id: root

  readonly property var player: {
    const players = Mpris.players.values
    if (!players || players.length === 0) return null
    return players.find(p => p.isPlaying)
        ?? players.find(p => p.canControl)
        ?? players[0]
  }

  available: player !== null && player.canControl
  playing: available && player.isPlaying
  playerName: available ? player.identity : ""
  title: available ? player.trackTitle : ""
  artist: available ? player.trackArtist : ""
  album: available ? player.trackAlbum : ""
  artUrl: available ? player.trackArtUrl : ""
  canNext: available && player.canGoNext
  canPrevious: available && player.canGoPrevious
  canSeek: available && player.canSeek
  position: available ? player.position : 0
  length: available ? player.length : 0

  function togglePlaying() {
    if (available && player.canTogglePlaying) player.togglePlaying()
  }

  function next() {
    if (canNext) player.next()
  }

  function previous() {
    if (canPrevious) player.previous()
  }

  function seekTo(seconds) {
    if (!canSeek || !player.positionSupported || !Number.isFinite(seconds)) return
    player.position = Math.max(0, Math.min(length, seconds))
  }
}
