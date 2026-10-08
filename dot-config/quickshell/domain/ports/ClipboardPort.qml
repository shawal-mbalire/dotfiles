// CONTRACT — ClipboardPort (text clipboard history)
//   list<string> history   newest first, unique, bounded        (read-only)
//   string       state     "loading"|"ready"|"unavailable"      (read-only)
//   copy(string text)
//     Pre:  text satisfies clipboard.isUsableText (otherwise ignored).
//     Post: text is the system selection and history[0] once it is observed back.
//   remove(string text)    Post: text is no longer in history.
//   clear()                Post: history is empty (the live selection is untouched).
//   Invariant: every history entry satisfies clipboard.isUsableText; no duplicates.
//   History persists across shell restarts; password-manager entries
//   (marked sensitive by the sender) are never recorded.
import QtQml

QtObject {
  property var history: []
  property string state: "loading"

  default property list<QtObject> resources

  function copy(text) {}
  function remove(text) {}
  function clear() {}
}
