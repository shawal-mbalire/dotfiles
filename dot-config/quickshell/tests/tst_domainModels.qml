// Pure domain functions. Run: qmltestrunner -input tests
import QtQuick
import QtTest
import "../domain/models/appSearch.js" as AppSearch
import "../domain/models/clipboard.js" as Clip
import "../domain/models/duration.js" as Duration
import "../domain/models/notification.js" as Notif
import "fixtures/apps.js" as Apps

TestCase {
  name: "DomainModels"

  function names(list) { return list.map(a => a.name) }

  // ── appSearch.filter ──────────────────────────────────────────────────────
  function test_emptyQueryReturnsAllInOrder() {
    compare(names(AppSearch.filter(Apps.SAMPLE, "   ")), names(Apps.SAMPLE))
  }

  function test_prefixBeatsWordPrefixBeatsContains() {
    // Two name prefixes (input order kept), then a comment match ("Redefined").
    compare(names(AppSearch.filter(Apps.SAMPLE, "fi")), ["Firefox", "Files", "Visual Studio Code"])
    compare(names(AppSearch.filter(Apps.SAMPLE, "code")), ["Visual Studio Code"])
    compare(names(AppSearch.filter(Apps.SAMPLE, "image"))[0], "GNU Image Manipulation Program")
  }

  function test_matchesGenericNameAndKeywords() {
    compare(names(AppSearch.filter(Apps.SAMPLE, "browser")), ["Firefox"])
    compare(names(AppSearch.filter(Apps.SAMPLE, "www")), ["Firefox"])
    compare(names(AppSearch.filter(Apps.SAMPLE, "terminal")), ["kitty"])
  }

  function test_subsequenceIsLastResort() {
    compare(names(AppSearch.filter(Apps.SAMPLE, "ffx")), ["Firefox"])
    compare(AppSearch.filter(Apps.SAMPLE, "zzz").length, 0)
  }

  function test_caseInsensitive() {
    compare(names(AppSearch.filter(Apps.SAMPLE, "KITTY")), ["kitty"])
  }

  // ── clipboard ─────────────────────────────────────────────────────────────
  function test_usableTextAcceptsNormalText() {
    verify(Clip.isUsableText("hello\tworld\r\n"))
  }

  function test_usableTextRejectsEmptyBinaryAndHuge() {
    verify(!Clip.isUsableText(""))
    verify(!Clip.isUsableText("   \n"))
    verify(!Clip.isUsableText("PNG\x00\x01"))
    verify(!Clip.isUsableText("x".repeat(32001)))
    verify(Clip.isUsableText("x".repeat(32000)))
  }

  function test_pushUniqueMovesToFrontAndBounds() {
    compare(Clip.pushUnique(["a", "b", "c"], "b", 5), ["b", "a", "c"])
    compare(Clip.pushUnique(["a", "b", "c"], "d", 3), ["d", "a", "b"])
  }

  function test_restoreSanitizesPersistedHistory() {
    compare(Clip.restore(["a", 3, "", "a", "b\x00", "c", "d"], 3), ["a", "c", "d"])
    compare(Clip.restore({ not: "an array" }, 5), [])
    compare(Clip.restore(null, 5), [])
  }

  function test_previewCollapsesWhitespace() {
    compare(Clip.preview("  a\n\n b\tc  "), "a b c")
  }

  // ── duration ──────────────────────────────────────────────────────────────
  function test_humanize() {
    compare(Duration.humanize(3900), "1h 5m")
    compare(Duration.humanize(600), "10m")
    compare(Duration.humanize(0), "")
    compare(Duration.humanize(-5), "")
    compare(Duration.humanize(NaN), "")
  }

  // ── notification ──────────────────────────────────────────────────────────
  function test_timeoutCriticalNeverExpires() {
    compare(Notif.timeoutMs(5000, true, false), 0)
  }

  function test_timeoutDefaultsByUrgency() {
    compare(Notif.timeoutMs(-1, false, false), 5000)
    compare(Notif.timeoutMs(0, false, true), 4000)
  }

  function test_timeoutSecondsAndCap() {
    compare(Notif.timeoutMs(3, false, false), 3000)
    compare(Notif.timeoutMs(8000, false, false), 8000)
    compare(Notif.timeoutMs(60000, false, false), 10000)
  }

  function test_plainTextStripsMarkup() {
    compare(Notif.plainText("<b>Hi</b> &amp; <i>bye</i>"), "Hi & bye")
    compare(Notif.plainText("a<br/>b"), "a\nb")
    compare(Notif.plainText("1 &lt; 2"), "1 < 2")
    compare(Notif.plainText(undefined), "")
  }
}
