// CONTRACT — AudioPort (default output sink)
//   bool ready    a default sink exists and is bound           (read-only)
//   bool muted                                                  (read-only)
//   int  volume   0-150, percent                                (read-only)
//   setVolume(int percent)
//     Pre:  percent is finite. Post: volume == clamp(round(percent), 0, 150) once the
//           sink reports back; no-op when !ready.
//   setMuted(bool muted)
//     Post: muted == value once the sink reports back; no-op when !ready.
//
// "read-only" is by contract: QML forbids a derived type from binding an
// inherited `readonly property`, so ports declare plain properties and only
// adapters may bind them. Consumers never write them.
import QtQml

QtObject {
  property bool ready: false
  property bool muted: false
  property int volume: 0

  // Lets adapters nest their private helpers (trackers, processes, timers).
  default property list<QtObject> resources

  function setVolume(percent) {}
  function setMuted(value) {}
}
