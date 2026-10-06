import "../Shared"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Overlay {
  id: root
  required property var modelData

  title: "Menu"
  shellNamespace: "quickshell:menu"
  implicitWidth: 420
  implicitHeight: 400
  screen: modelData

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property string searchText: ""
  property var filtered: []
  property var allApps: []
  property var pendingApps: []
  property int selectedIndex: 0
  property string loadState: "idle"   // idle | loading | ready | empty | timeout
  property double lastPublish: 0

  // Emitting names/Exec lines as <name><US><exec> keeps values with | or
  // quotes intact. Missing directories are skipped instead of aborting find,
  // and -maxdepth 1 keeps flatpak/FUSE trees from stalling the scan.
  readonly property string appScanScript: `
for d in /usr/share/applications /usr/local/share/applications "$HOME/.local/share/applications" /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications"; do
  [ -d "$d" ] || continue
  find "$d" -maxdepth 1 -type f -name '*.desktop' 2>/dev/null
done | sort -u | head -400 | while IFS= read -r f; do
  awk '/^\\[Desktop Entry\\]/{g=1;next} /^\\[/{g=0} g&&/^Name=/&&n==""{n=substr($0,6)} g&&/^Exec=/&&e==""{e=substr($0,6)} g&&/^(Hidden|NoDisplay)=true/{s=1} END{if(!s&&n!=""&&e!="") printf "%s%c%s\\n", n, 29, e}' "$f"
done
`

  Process {
    id: listApps
    command: ["bash", "-c", root.appScanScript]
    running: false
    stdout: SplitParser {
      onRead: data => root.absorb(data)
    }
    onExited: root.finishLoad()
  }

  // Safety net: if the scan hangs (slow/unavailable mount) publish whatever
  // arrived so the list is never silently blank.
  Timer {
    id: safetyTimer
    interval: 4000
    running: root.loadState === "loading"
    repeat: false
    onTriggered: {
      if (root.loadState !== "loading") return
      root.publish()
      root.loadState = root.allApps.length > 0 ? "ready" : "timeout"
    }
  }

  function startLoad() {
    if (listApps.running) return
    if (allApps.length > 0) {
      loadState = "ready"
      applyFilter()
      return
    }
    pendingApps = []
    allApps = []
    filtered = []
    lastPublish = 0
    selectedIndex = 0
    loadState = "loading"
    listApps.running = true
  }

  function absorb(line) {
    const text = line.replace(/\r$/, "")
    const sep = String.fromCharCode(29)
    const i = text.indexOf(sep)
    if (i <= 0) return
    const name = text.slice(0, i).trim()
    const exec = text.slice(i + 1).trim()
    if (!name || !exec) return
    pendingApps.push({ name: name, exec: exec })
    const now = Date.now()
    if (now - lastPublish > 200) {
      lastPublish = now
      publish()
    }
  }

  function publish() {
    allApps = pendingApps.slice()
    applyFilter()
  }

  function finishLoad() {
    lastPublish = 0
    publish()
    loadState = allApps.length > 0 ? "ready" : "empty"
  }

  function applyFilter() {
    const q = searchText.toLowerCase()
    filtered = q === "" ? allApps.slice() : allApps.filter(a => a.name.toLowerCase().includes(q))
    if (selectedIndex >= filtered.length) selectedIndex = Math.max(0, filtered.length - 1)
  }

  // Desktop Entry Exec parsing. Field codes are dropped and the line is
  // tokenised in QML so it never has to travel through a shell.
  function stripFieldCodes(s) {
    let out = ""
    for (let i = 0; i < s.length; i++) {
      if (s[i] === "%") {
        if (s[i + 1] === "%") { out += "%"; i++ }
        else i++
        continue
      }
      out += s[i]
    }
    return out
  }

  function tokenizeExec(exec) {
    const raw = []
    let cur = ""
    let inQuote = false
    let has = false
    for (let i = 0; i < exec.length; i++) {
      const c = exec[i]
      if (inQuote) {
        if (c === "\\" && i + 1 < exec.length) { cur += exec[++i]; has = true; continue }
        if (c === '"') { inQuote = false; continue }
        cur += c
        has = true
        continue
      }
      if (c === '"') { inQuote = true; has = true; continue }
      if (c === " " || c === "\t") {
        if (has) { raw.push(cur); cur = ""; has = false }
        continue
      }
      cur += c
      has = true
    }
    if (has) raw.push(cur)

    const argv = []
    for (let i = 0; i < raw.length; i++) {
      const token = stripFieldCodes(raw[i]).trim()
      if (token.length > 0) argv.push(token)
    }
    return argv
  }

  function launchSelected() {
    if (filtered.length === 0) return
    const idx = Math.max(0, Math.min(selectedIndex, filtered.length - 1))
    const argv = tokenizeExec(filtered[idx].exec)
    if (argv.length === 0) return
    Quickshell.execDetached(argv)
    root.searchText = ""
    root.closeRequested()
  }

  Component.onCompleted: startLoad()

  onVisibleChanged: {
    if (!visible) return
    input.text = ""
    searchText = ""
    selectedIndex = 0
    startLoad()
    focusTimer.restart()
  }

  Timer {
    id: focusTimer
    interval: 50
    onTriggered: input.forceActiveFocus()
  }

  readonly property string statusText: {
    if (loadState === "loading") return "Loading applications…"
    if (loadState === "timeout") return "App scan timed out"
    if (loadState === "empty") return "No applications found"
    return "No matches"
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.paddingLg
    spacing: Theme.spacingLg

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 36
      radius: Theme.radiusSm
      color: Theme.surface0

      TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: Theme.paddingSm
        color: Theme.text
        selectionColor: Theme.blue
        font { family: Theme.font; pixelSize: 14; weight: 600 }
        clip: true
        focus: true

        onTextChanged: {
          root.searchText = text
          root.applyFilter()
        }

        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filtered.length - 1))
        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        Keys.onReturnPressed: root.launchSelected()
        Keys.onEscapePressed: root.closeRequested()

        Text {
          visible: input.text === "" && !input.activeFocus
          text: "Search apps..."
          color: Theme.overlay0
          font: input.font
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.surface1 }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      visible: root.filtered.length > 0
      model: root.filtered
      currentIndex: root.selectedIndex

      delegate: Rectangle {
        required property var modelData
        required property int index
        height: 34
        radius: Theme.radiusSm
        color: index === root.selectedIndex ? Theme.surface1 : "transparent"

        Text {
          anchors.fill: parent
          anchors.margins: Theme.paddingSm
          text: modelData.name
          color: Theme.text
          font { family: Theme.font; pixelSize: 13; weight: 600 }
          elide: Text.ElideRight
          verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onDoubleClicked: root.launchSelected()
          onContainsMouseChanged: { if (containsMouse) root.selectedIndex = index }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.filtered.length === 0

      Text {
        anchors.centerIn: parent
        text: root.statusText
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 12; weight: 600 }
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
