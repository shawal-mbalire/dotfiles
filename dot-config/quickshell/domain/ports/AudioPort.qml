// CONTRACT — AudioPort (default output sink)
//   bool   ready      a default sink exists and is bound            (read-only)
//   bool   muted                                                    (read-only)
//   int    volume     percent; may exceed the write ceiling only if the sink was already boosted
//   string sinkName   node name of the default sink, "" when none  (read-only)
//   list<var> sinks   eligible audio sinks as { name, label }; AirPlay and Mac mini sinks are
//                     never listed or used (domain/models/Sinks.qml)               (read-only)
//   string sourceName  node name of the default input (microphone), "" when none (read-only)
//   list<var> sources  eligible audio inputs as { name, label }; monitor sources are never
//                      listed (domain/models/Sources.qml)                       (read-only)
//   setVolume(int percent)
//     Pre:  percent is finite, >= 0, and not above max(ceiling, volume) (ValidationError
//           otherwise). The ceiling is Bounds.volumeMax (100): lowering is always allowed,
//           raising above the ceiling is refused.
//     Post: volume == percent once the sink reports back. Logged no-op when !ready.
//   setMuted(bool muted)
//     Pre:  muted is a boolean (ValidationError otherwise).
//     Post: muted == value once the sink reports back. Logged no-op when !ready.
//   setDefaultSink(string name)
//     Pre:  name is the name of an entry of `sinks` (ValidationError otherwise).
//     Post: name is kept as the preferred sink; it becomes the default whenever it is
//           present, including after it reconnects. Logged no-op when absent.
//   setDefaultSource(string name)
//     Pre:  name is the name of an entry of `sources` (ValidationError otherwise).
//     Post: name is the preferred input while it is present. The default input is not
//           moved while the preferred input is absent.
//   Callers may rely on: the default sink is not silently abandoned while the preferred
//   sink is present.
//
// "read-only" is by contract: QML forbids a derived type from binding an
// inherited `readonly property`, so ports declare plain properties and only
// adapters may bind them. Consumers never write them.
import QtQml

QtObject {
  property bool ready: false
  property bool muted: false
  property int volume: 0
  property string sinkName: ""
  property var sinks: []
  property string sourceName: ""
  property var sources: []

  // Lets adapters nest their private helpers (trackers, processes, timers).
  default property list<QtObject> resources

  function setVolume(percent) {}
  function setMuted(value) {}
  function setDefaultSink(name) {}
  function setDefaultSource(name) {}
}
