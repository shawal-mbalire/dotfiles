// FeedbackPort over ffplay's lavfi sine generator.
//
// The tone is routed through the default sink, so its loudness also tracks the
// system volume, and its pitch is mapped across [minHz, maxHz] for the level.
// While a tone is sounding further requests are dropped (the Process is the
// coalescing point), which keeps a fast wheel scroll from spawning a process
// per step.
import QtQml
import Quickshell.Io
import "../../../domain/ports"

FeedbackPort {
  id: root

  property int minHz: 320
  property int maxHz: 1180
  property real duration: 0.08

  function playTone(level) {
    if (tone.running || !Number.isFinite(level)) return
    const ratio = Math.max(0, Math.min(100, level)) / 100
    const hz = Math.round(root.minHz + (root.maxHz - root.minHz) * ratio)
    tone.exec(["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet",
               "-f", "lavfi", "-i", "sine=frequency=" + hz + ":duration=" + root.duration])
  }

  Process {
    id: tone
    onExited: exitCode => {
      if (exitCode !== 0) console.warn("[feedback] ffplay exited with", exitCode)
    }
  }
}
