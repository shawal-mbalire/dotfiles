// FeedbackPort over ffplay's lavfi sine generator.
//
// The tone is routed through the default sink, so its loudness also tracks the
// system volume, and its pitch is mapped across [minHz, maxHz] for the level.
// While a tone is sounding further requests are dropped (the Process is the
// coalescing point), which keeps a fast wheel scroll from spawning a process
// per step. A watchdog kills a player that outlives its tone, and repeated
// failures switch feedback off for the session instead of retrying forever.
import QtQml
import Quickshell.Io
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

FeedbackPort {
  id: root

  property int minHz: 320
  property int maxHz: 1180
  property real duration: 0.08
  property int maxPlayMs: 1000
  property int maxFailures: 3

  property int failStreak: 0

  // Probe once at startup: without ffplay, feedback is disabled and reported once.
  Process {
    id: probe
    command: ["sh", "-c", "command -v ffplay >/dev/null"]
    running: true
    onExited: exitCode => {
      root.available = exitCode === 0
      if (!root.available) console.warn("[feedback] ffplay not found; volume tones disabled")
    }
  }

  // Pre: level is a finite number >= 0. Requests while a tone plays are coalesced.
  function playTone(level) {
    Errors.precondition(Contracts.isNonNegative(level), "feedback.level-invalid",
                        "level must be a finite number >= 0", { level: level })
    if (!root.available || tone.running) return
    const ratio = Math.max(0, Math.min(100, level)) / 100
    const hz = Math.round(root.minHz + (root.maxHz - root.minHz) * ratio)
    watchdog.restart()
    tone.exec(["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet",
               "-f", "lavfi", "-i", "sine=frequency=" + hz + ":duration=" + root.duration])
  }

  Process {
    id: tone
    onExited: exitCode => {
      watchdog.stop()
      if (exitCode === 0) {
        root.failStreak = 0
        return
      }
      root.failStreak++
      console.warn("[feedback] ffplay exited with", exitCode,
                   "(failure", root.failStreak, "of", root.maxFailures + ")")
      if (root.failStreak >= root.maxFailures) {
        root.available = false
        console.warn("[feedback] disabled for this session after repeated failures")
      }
    }
  }

  Timer {
    id: watchdog
    interval: root.maxPlayMs
    onTriggered: {
      console.warn("[feedback] ffplay ran past", root.maxPlayMs, "ms; killing it")
      tone.running = false
    }
  }
}
