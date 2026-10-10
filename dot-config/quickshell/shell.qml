// Composition root: create one adapter per capability, inject them as ports,
// start the driving surface. No business logic lives here.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "infra/config"
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
  SysfsBrightnessAdapter { id: brightness; device: "intel_backlight" }
  NetworkingWifiAdapter { id: network }
  GammastepColorCorrectionAdapter { id: colorCorrection; temperature: 16000 }
  PowerProfilesAdapter { id: powerProfiles }
  WlClipboardAdapter { id: clipboard; maxItems: 50; storePath: Quickshell.statePath("clipboard.json") }
  DesktopEntriesLaunchAdapter { id: launcher; terminalCommand: ["kitty", "-e"] }
  MprisMediaAdapter { id: media }
  PipewireToneAdapter { id: feedback }
  HyprlandWallpaperAdapter { id: wallpaper; directory: Config.wallpaperDir }
  NotificationServerAdapter { id: notificationFeed; maxVisible: 5; maxHistory: 20 }
  HyprlandWorkspaceAdapter { id: workspaces }

  ConnectionNoticeWorkflow { bluetoothPort: bluetooth; networkPort: network; feedPort: notificationFeed }

  // ── Auto-hidden bar ──────────────────────────────────────────────────────
  // Hidden until the pointer reaches the top (Bar/TopEdgeReveal), enters the
  // top-right hot corner, or the `bar` IPC toggle pins it. The bar and the
  // control center are treated as one object: while the control center is open
  // the bar stays, and dismissing the control center lets the bar hide with it.
  property bool barVisible: false
  property bool barPinned: false
  property bool barHovered: false
  property bool stripHovered: false
  property bool cornerHovered: false
  property int barHideDelay: 500

  function updateBar() {
    if (barPinned || barHovered || stripHovered || cornerHovered || controlCenterSlot.open) {
      barHideTimer.stop()
      barVisible = true
    } else {
      barHideTimer.restart()
    }
  }

  function toggleBar() {
    barPinned = !barPinned
    updateBar()
  }

  // The hot corner is a single action: bar up and control center open, always
  // together, never one without the other.
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

  // Each overlay opens on the focused monitor and stays mounted until its
  // exit animation has finished.
  OverlaySlot { id: menuSlot }
  OverlaySlot { id: clipboardSlot }
  OverlaySlot { id: controlCenterSlot }

  function focusedScreen() {
    const name = Hyprland.focusedMonitor?.name
    return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { root.toggleBar() }
  }

  // Called by the brightness keybinds after they change the backlight.
  IpcHandler {
    target: "brightness"
    function refresh(): void { brightness.refresh() }
  }

  IpcHandler {
    target: "menu"
    function toggle(): void { menuSlot.toggle(root.focusedScreen()) }
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { clipboardSlot.toggle(root.focusedScreen()) }
  }

  IpcHandler {
    target: "controlCenter"
    function toggle(): void {
      controlCenterSlot.toggle(root.focusedScreen())
      root.updateBar()
    }
  }

  // ── Volume / brightness OSD ──────────────────────────────────────────────
  // Shown when a level changes outside the control center (bar scroll, media
  // keys); the control center's own sliders are their own feedback.
  property string osdKind: "volume"
  property int osdLevel: 0
  property bool osdActive: false
  // Ignore the initial 0 -> real sink/brightness values at startup.
  property bool levelFeedbackReady: false

  Timer {
    id: levelFeedbackArm
    interval: 1500
    running: true
    onTriggered: root.levelFeedbackReady = true
  }

  Timer {
    id: osdHide
    interval: 1100
    onTriggered: root.osdActive = false
  }

  function showOsd(kind, level) {
    root.osdKind = kind
    root.osdLevel = Math.round(level)
    root.osdActive = true
    osdHide.restart()
  }

  Connections {
    target: audio
    function onVolumeChanged() {
      if (!root.levelFeedbackReady || controlCenterSlot.open) return
      root.showOsd("volume", audio.volume)
      if (!audio.muted && feedback.available) feedback.playTone(audio.volume)
    }
  }

  Connections {
    target: brightness
    function onPercentChanged() {
      if (!root.levelFeedbackReady || controlCenterSlot.open) return
      root.showOsd("brightness", brightness.percent)
    }
  }

  // ── Colour scheme: the adapter owns the desktop setting, Theme only renders it
  GnomeColorSchemeAdapter { id: colorScheme }
  Binding {
    target: Theme
    property: "darkMode"
    value: colorScheme.darkMode
  }

  // ── Bar, one per screen ──────────────────────────────────────────────────
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.barVisible

      anchors {
        top: true
        left: true
        right: true
      }

      // Auto-hiding: must not reserve space, or tiled windows reflow on every hide.
      exclusiveZone: 0
      implicitHeight: Theme.barHeight
      color: Theme.mantle

      // Full-bleed so the hover handler covers the whole bar, not just the
      // content inset; margins move to the left/right groups.
      Item {
        anchors.fill: parent

        // Keep the bar up while the pointer is on it; hiding is deferred so the
        // pointer can travel between the bar and the top-edge strip.
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

        Clock {
          anchors.centerIn: parent
        }

        RowLayout {
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          spacing: 20

          ColorCorrection { colorCorrectionPort: colorCorrection }
          Network { networkPort: network }
          Bluetooth { bluetoothPort: bluetooth }
          Volume { audioPort: audio }
          Brightness { brightnessPort: brightness }
          Battery { batteryPort: battery }
        }
      }
    }
  }

  // ── Top-edge reveal strip + hot corner, one of each per screen ───────────
  Variants {
    model: Quickshell.screens

    TopEdgeReveal {
      // Edge hover pins the bar open; leaving arms the hide timer.
      onHoverEntered: { root.stripHovered = true; root.updateBar() }
      onHoverExited: { root.stripHovered = false; root.updateBar() }
    }
  }

  Variants {
    model: Quickshell.screens

    HotCorner {
      onHoverEntered: { root.cornerHovered = true; root.updateBar() }
      onHoverExited: { root.cornerHovered = false; root.updateBar() }
      onTriggered: root.openControlCenterFromCorner()
    }
  }

  // ── Level OSD, on the focused screen ─────────────────────────────────────
  Osd {
    screen: root.focusedScreen()
    kind: root.osdKind
    level: root.osdLevel
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
        root.updateBar()
      }
      onClearNotificationsRequested: notificationFeed.clearHistory()
    }
  }

  Wallpapers { wallpaperPort: wallpaper }
}
