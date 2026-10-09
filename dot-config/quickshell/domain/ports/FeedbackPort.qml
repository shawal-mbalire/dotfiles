// CONTRACT — FeedbackPort (audible level cue)
//   playTone(int level)
//     Pre:  level is finite.
//     Post: a short tone plays on the default sink; its pitch rises with level
//           (0-100). Calls made while a tone is still playing coalesce — the
//           next one is dropped rather than queued, so a fast scroll does not
//           spawn a process per step.
import QtQml

QtObject {
  default property list<QtObject> resources

  function playTone(level) {}
}
