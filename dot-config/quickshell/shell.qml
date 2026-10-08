// Composition root: create one adapter per capability, inject them as ports,
// start the driving surface. No business logic lives here.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "Bar"
import "Menus"
import "Shared"
import "ControlCenter"
import "adapters/driven/pipewire"
import "adapters/driven/upower"
import "adapters/driven/bluetooth"
import "adapters/driven/brightness"
import "adapters/driven/network"
import "adapters/driven/gammastep"
import "adapters/driven/wl-clipboard"
import "adapters/driven/desktop-entries"

ShellRoot {
  id: root

  // ── Driven adapters (one instance each, shared by every screen) ──────────
  PipewireAudioAdapter { id: audio }
  UPowerBatteryAdapter { id: battery }
  BluezBluetoothAdapter { id: bluetooth }
  SysfsBrightnessAdapter { id: brightness; device: "intel_backlight" }
  NetworkingWifiAdapter { id: network }
  GammastepNightLightAdapter { id: nightLight; temperature: 16000 }
  WlClipboardAdapter { id: clipboard; maxItems: 50; storePath: Quickshell.statePath("clipboard.json") }
  DesktopEntriesLaunchAdapter { id: launcher; terminalCommand: ["kitty", "-e"] }

  // ── Visibility state, toggled over IPC ───────────────────────────────────
  property bool barVisible: true

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
    function toggle(): void { root.barVisible = !root.barVisible }
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
    function toggle(): void { controlCenterSlot.toggle(root.focusedScreen()) }
  }

  // ── Colour scheme sync with GNOME settings ───────────────────────────────
  function applyThemeLine(line) {
    if (line.indexOf("prefer-dark") >= 0) Theme.darkMode = true
    else if (line.indexOf("prefer-light") >= 0) Theme.darkMode = false
  }

  function setDarkMode(enabled) {
    Theme.darkMode = enabled
    Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
                             enabled ? "prefer-dark" : "prefer-light"])
  }

  Process {
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser { onRead: data => root.applyThemeLine(data) }
  }

  Process {
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser { onRead: data => root.applyThemeLine(data) }
    onExited: exitCode => console.warn("[theme] gsettings monitor exited with", exitCode)
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

      implicitHeight: 30
      color: Theme.mantle

      Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        RowLayout {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Workspaces {}
          SystemTray {}
        }

        Clock {
          anchors.centerIn: parent
        }

        RowLayout {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 20

          Gammastep { nightLightPort: nightLight }
          Network { networkPort: network }
          Bluetooth { bluetoothPort: bluetooth }
          Volume { audioPort: audio }
          Brightness { brightnessPort: brightness }
          Battery { batteryPort: battery }
        }
      }
    }
  }

  // ── Notification popups (single daemon) ──────────────────────────────────
  Notifications { id: notifications }

  // ── Overlays: created on open, destroyed after their exit animation ──────
  LazyLoader {
    active: menuSlot.mounted

    Menu {
      screen: menuSlot.screen
      open: menuSlot.open
      launchPort: launcher
      onCloseRequested: menuSlot.close()
      onClosed: menuSlot.unmount()
    }
  }

  LazyLoader {
    active: clipboardSlot.mounted

    Clipboard {
      screen: clipboardSlot.screen
      open: clipboardSlot.open
      clipboardPort: clipboard
      onCloseRequested: clipboardSlot.close()
      onClosed: clipboardSlot.unmount()
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
      nightLightPort: nightLight
      notificationHistory: notifications.history
      onCloseRequested: controlCenterSlot.close()
      onClosed: controlCenterSlot.unmount()
      onDarkModeRequested: enabled => root.setDarkMode(enabled)
      onClearNotificationsRequested: notifications.clearHistory()
    }
  }

  Wallpapers {}
}
