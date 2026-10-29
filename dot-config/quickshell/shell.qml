// Composition root: create one adapter per capability, inject them as ports,
// start the driving surface. No business logic lives here.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "infra/config"
import "domain/constants"
import "adapters/driving/Bar"
import "adapters/driving/ControlCenter"
import "adapters/driving/Menus"
import "adapters/driving/Notifications"
import "adapters/driving/Shared"
import "adapters/driven"
import "domain/workflows"

ShellRoot {
  id: root

  // ── Driven adapters (one instance each, shared by every screen) ──────────
  PipewireAudioAdapter { id: audio; preferredSink: Config.preferredSink }
  UPowerBatteryAdapter { id: battery }
  BluezBluetoothAdapter { id: bluetooth }
  SysfsBrightnessAdapter { id: brightness; device: Config.backlight }
  NetworkingWifiAdapter { id: network }
  GammastepColorCorrectionAdapter { id: colorCorrection; temperature: Config.colorTemperature }
  PowerProfilesAdapter { id: powerProfiles }
  WlClipboardAdapter { id: clipboard; maxItems: 50; storePath: Quickshell.statePath("clipboard.json") }
  DesktopEntriesLaunchAdapter { id: launcher; terminalCommand: ["kitty", "-e"] }
  MprisMediaAdapter { id: media }
  PipewireToneAdapter { id: feedback }
  DirectoryWallpaperAdapter { id: wallpaper; directory: Config.wallpaperDir; autoApply: true }
  NotificationServerAdapter { id: notificationFeed; maxVisible: 5; maxHistory: 20 }
  HyprlandWorkspaceAdapter { id: workspaces }

  ConnectionNoticeWorkflow { bluetoothPort: bluetooth; networkPort: network; feedPort: notificationFeed }

  // ── Auto-hidden bar ──────────────────────────────────────────────────────
  property bool barVisible: false
  property bool barPinned: false
  property bool barHovered: false
  property bool stripHovered: false
  property bool cornerHovered: false
  property int barHideDelay: 500

  function updateBar(immediate) {
    if (barPinned || barHovered || stripHovered || cornerHovered || controlCenterSlot.open) {
      barHideTimer.stop()
      barVisible = true
    } else if (immediate) {
      barHideTimer.stop()
      barVisible = false
    } else {
      barHideTimer.restart()
    }
  }

  function toggleBar() { barPinned = !barPinned; updateBar() }

  function openControlCenterFromCorner() {
    barVisible = true
    if (!controlCenterSlot.open) controlCenterSlot.toggle(root.focusedScreen())
    updateBar()
  }

  Timer {
    id: barHideTimer
    interval: root.barHideDelay
    onTriggered: if (!root.barPinned) root.barVisible = false
  }

  OverlaySlot { id: menuSlot }
  OverlaySlot { id: clipboardSlot }
  OverlaySlot { id: controlCenterSlot }

  function focusedScreen() {
    const name = Hyprland.focusedMonitor?.name
    return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
  }

  IpcHandler { target: "bar"; function toggle(): void { root.toggleBar() } }

  IpcHandler {
    target: "audio"
    function up(): void { audio.step(Bounds.volumeStep) }
    function down(): void { audio.step(-Bounds.volumeStep) }
    function toggleMute(): void { audio.setMuted(!audio.muted) }
    function toggleMicMute(): void { audio.toggleSourceMuted() }
  }

  IpcHandler {
    target: "brightness"
    function up(): void { brightness.step(Bounds.brightnessStep) }
    function down(): void { brightness.step(-Bounds.brightnessStep) }
    function refresh(): void { brightness.refresh() }
  }

  IpcHandler { target: "menu"; function toggle(): void { menuSlot.toggle(root.focusedScreen()) } }
  IpcHandler { target: "clipboard"; function toggle(): void { clipboardSlot.toggle(root.focusedScreen()) } }
  IpcHandler {
    target: "controlCenter"
    function toggle(): void {
      controlCenterSlot.toggle(root.focusedScreen())
      root.updateBar()
    }
  }

  IpcHandler {
    target: "wallpapers"
    function refresh(): void { wallpaper.refresh() }
    function set(path: string): void { wallpaper.set(path) }
    function next(): void { wallpaper.next() }
    function prev(): void { wallpaper.previous() }
    function random(): void { wallpaper.random() }
    function list(): string { return wallpaper.wallpapers.join("\n") }
    function current(): string { return wallpaper.current }
  }

  // ── Volume / brightness OSD ──────────────────────────────────────────────
  property string osdKind: "volume"
  property int osdLevel: 0
  property bool osdMuted: false
  property bool osdActive: false
  property bool levelFeedbackReady: false

  Timer { id: levelFeedbackArm; interval: 1500; running: true; onTriggered: root.levelFeedbackReady = true }
  Timer { id: osdHide; interval: 1100; onTriggered: root.osdActive = false }

  function showOsd(kind, level, muted) {
    root.osdKind = kind
    root.osdLevel = Math.round(level)
    root.osdMuted = muted === true
    root.osdActive = true
    osdHide.restart()
  }

  Connections {
    target: audio
    function onVolumeChanged() {
      if (!root.levelFeedbackReady || controlCenterSlot.open) return
      root.showOsd("volume", audio.volume, audio.muted)
      if (!audio.muted && feedback.available) feedback.playTone(audio.volume)
    }
    function onMutedChanged() {
      if (!root.levelFeedbackReady || controlCenterSlot.open) return
      root.showOsd("volume", audio.volume, audio.muted)
    }
  }

  Connections {
    target: brightness
    function onPercentChanged() {
      if (!root.levelFeedbackReady || controlCenterSlot.open) return
      root.showOsd("brightness", brightness.percent)
    }
  }

  GnomeColorSchemeAdapter { id: colorScheme }
  Binding { target: Theme; property: "darkMode"; value: colorScheme.darkMode }

  // ── Bar, one per screen ──────────────────────────────────────────────────
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData

      property bool shown: root.barVisible
      property bool mounted: false
      visible: mounted
      onShownChanged: {
        if (shown) {
          mounted = true
          barExit.stop()
          barEnter.restart()
        } else {
          barEnter.stop()
          barExit.restart()
        }
      }

      ParallelAnimation {
        id: barEnter
        NumberAnimation { target: barSlide; property: "y"; to: 0; duration: Theme.animSlow; easing.type: Theme.easeOut }
        NumberAnimation { target: barPanel; property: "opacity"; to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
      }

      ParallelAnimation {
        id: barExit
        NumberAnimation { target: barSlide; property: "y"; to: -Theme.barHeight; duration: Theme.animFast; easing.type: Theme.easeIn }
        NumberAnimation { target: barPanel; property: "opacity"; to: 0; duration: Theme.animFast; easing.type: Theme.easeIn }
        onFinished: if (!barWindow.shown) barWindow.mounted = false
      }

      anchors { top: true; left: true; right: true }
      exclusiveZone: 0
      mask: Region { item: barPanel }
      implicitHeight: Theme.barHeight
      color: Theme.glass(Theme.mantle)
      WlrLayershell.namespace: "quickshell:bar"

      Item {
        id: barPanel
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: barSlide; y: -Theme.barHeight }

        HoverHandler {
          onHoveredChanged: {
            root.barHovered = hovered
            root.updateBar()
          }
        }

        RowLayout {
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Workspaces { workspacePort: workspaces }
          SystemTray {}
        }

        Clock { anchors.centerIn: parent }

        BarIndicators {
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          colorCorrectionPort: colorCorrection
          networkPort: network
          bluetoothPort: bluetooth
          audioPort: audio
          brightnessPort: brightness
          batteryPort: battery
        }
      }
    }
  }

  // ── Top-edge sensors (reveal strip + hot corner), one per screen ─────────
  Variants {
    model: Quickshell.screens
    TopEdgeSensors {
      onHoverEntered: { root.stripHovered = true; root.updateBar() }
      onHoverExited: { root.stripHovered = false; root.updateBar() }
      onTriggered: root.openControlCenterFromCorner()
    }
  }

  // ── Level OSD, on the focused screen ─────────────────────────────────────
  Osd {
    screen: root.focusedScreen()
    kind: root.osdKind
    level: root.osdLevel
    muted: root.osdMuted
    active: root.osdActive
  }

  // ── Notification popups (single daemon) ──────────────────────────────────
  Notifications { feedPort: notificationFeed }

  // ── Overlays: created on open, destroyed after their exit animation ──────
  LazyLoader {
    active: menuSlot.mounted
    Menu {
      screen: menuSlot.screen
      open: menuSlot.open
      launchPort: launcher
      onCloseRequested: menuSlot.close()
      onCloseFinished: menuSlot.unmount()
    }
  }

  LazyLoader {
    active: clipboardSlot.mounted
    Clipboard {
      screen: clipboardSlot.screen
      open: clipboardSlot.open
      clipboardPort: clipboard
      onCloseRequested: clipboardSlot.close()
      onCloseFinished: clipboardSlot.unmount()
    }
  }

  LazyLoader {
    active: controlCenterSlot.mounted
    ControlCenter {
      screen: controlCenterSlot.screen
      open: controlCenterSlot.open
      audioPort: audio
      brightnessPort: brightness
      batteryPort: battery
      networkPort: network
      bluetoothPort: bluetooth
      colorCorrectionPort: colorCorrection
      powerProfilePort: powerProfiles
      colorSchemePort: colorScheme
      mediaPort: media
      notificationHistory: notificationFeed.history
      onCloseRequested: controlCenterSlot.close()
      onCloseFinished: {
        controlCenterSlot.unmount()
        root.updateBar(true)
      }
      onClearNotificationsRequested: notificationFeed.clearHistory()
    }
  }

  // ── Wallpaper, one background surface per screen ─────────────────────────
  Variants {
    model: Quickshell.screens
    WallpaperBackground { wallpaperPort: wallpaper }
  }
}
