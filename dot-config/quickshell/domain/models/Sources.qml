pragma Singleton
import QtQml

// Inputs the shell offers as the default microphone. A monitor source mirrors an
// output's audio rather than capturing a microphone, so it is never listed.
// Matched against node.name, case-insensitively.
QtObject {
  readonly property var excluded: [/\.monitor$/i]

  function isEligible(name) {
    const text = name || ""
    return !excluded.some(pattern => pattern.test(text))
  }
}
