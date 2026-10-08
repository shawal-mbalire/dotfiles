import QtQml
import "../../domain/ports"
import "../../domain/models/clipboard.js" as Clip

ClipboardPort {
  property var copied: []
  state: "ready"
  history: ["first entry", "second entry", "third\nmultiline entry"]
  function copy(text) { copied = copied.concat([text]); history = Clip.pushUnique(history, text, 50) }
  function remove(text) { history = history.filter(t => t !== text) }
  function clear() { history = [] }
}
