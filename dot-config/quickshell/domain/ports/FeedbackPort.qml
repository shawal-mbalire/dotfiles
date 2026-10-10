// CONTRACT — FeedbackPort (audible level cue)
//   bool available   the cue can play; false when the player is missing or disabled
//                    after repeated failures                                (read-only)
//   Callers do not request cues while the sink is muted.
//   playTone(int level)
//     Pre:  level is a finite number >= 0 (ValidationError otherwise).
//     Post: a short tone plays on the default sink; its pitch rises with level
//           (0-100). Calls made while a tone is still playing coalesce — the
//           next one is dropped rather than queued, so a fast scroll does not
//           spawn a process per step.
import QtQml

QtObject {
  property bool available: true

  default property list<QtObject> resources

  function playTone(level) {}
}
