// CONTRACT — MediaPort (active MPRIS player)
// The one live media player the shell shows and drives. Every member is
// read-only by contract: adapters bind them, consumers never write them.
//
//   bool   available    a controllable player exists                    (read-only)
//   bool   playing      transport is playing                            (read-only)
//   string playerName   MPRIS identity, e.g. "Spotify", "" when none    (read-only)
//   string title        current track title, "" when none               (read-only)
//   string artist       current track artist, "" when none              (read-only)
//   string album        current track album, "" when none               (read-only)
//   string artUrl       cover art URL/path, "" when none                (read-only)
//   bool   canNext      player accepts next/previous                    (read-only)
//   bool   canPrevious  player accepts next/previous                    (read-only)
//   bool   canSeek      absolute seeks are supported                    (read-only)
//   real   position     elapsed seconds, 0 when unknown                 (read-only)
//   real   length       total seconds, 0 when unknown                   (read-only)
//
//   togglePlaying()   play/pause the active player.    No-op when !available.
//   next()            skip forward.                    No-op unless canNext.
//   previous()        skip back.                       No-op unless canPrevious.
//   seekTo(seconds)   seek to an absolute position.
//     Pre:  seconds is finite.
//     Post: position == clamp(seconds, 0, length) once the player confirms.
//           No-op unless canSeek.
import QtQml

QtObject {
  property bool available: false
  property bool playing: false
  property string playerName: ""
  property string title: ""
  property string artist: ""
  property string album: ""
  property string artUrl: ""
  property bool canNext: false
  property bool canPrevious: false
  property bool canSeek: false
  property real position: 0
  property real length: 0

  // Lets adapters nest their private helpers (trackers, models, timers).
  default property list<QtObject> resources

  function togglePlaying() {}
  function next() {}
  function previous() {}
  function seekTo(seconds) {}
}
