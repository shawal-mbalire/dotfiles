pragma Singleton
import QtQml

// Sinks the shell never uses as output.
// - AirPlay (RAOP) speakers, including the Mac mini, appear and vanish on their
//   own, and a stream left on one is silent.
// - HDMI / DisplayPort outputs of the laptop's sound card. They are listed even
//   when nothing is plugged in, and the built-in speakers are the one real output
//   of the machine, so the picker treats them as a single sink.
// Matched against node.name and node.description, case-insensitively.
QtObject {
  readonly property var excluded: [/^raop_sink\./i, /airplay/i, /mac\s*mini/i, /hdmi|displayport/i]

  function isEligible(name, description) {
    const text = (name || "") + " " + (description || "")
    return !excluded.some(pattern => pattern.test(text))
  }
}
