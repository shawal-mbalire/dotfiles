import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import QtQuick

import "Bar"
import "Menus"
import "Shared"
import "ControlCenter"
//

ShellRoot {
  id: root

  property bool barVisible: true
  property bool menuVisible: false
  property bool clipboardVisible: false
  property bool controlCenterVisible: false

  // One handler per target, declared once here. Handlers used to live inside
  // the per-screen Variants, which registered duplicate targets (Quickshell
  // keeps only the first and warns about the rest).
  IpcHandler {
    target: "bar"
    function toggle(): void { root.barVisible = !root.barVisible }
  }

  IpcHandler {
    target: "menu"
    function toggle(): void { root.menuVisible = !root.menuVisible }
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { root.clipboardVisible = !root.clipboardVisible }
  }

  IpcHandler {
    target: "controlCenter"
    function toggle(): void { root.controlCenterVisible = !root.controlCenterVisible }
  }

  function applyThemeLine(line) {
    if (line.indexOf("prefer-dark") >= 0) Theme.darkMode = true
    else if (line.indexOf("prefer-light") >= 0) Theme.darkMode = false
  }

  Process {
    id: themeReadProc
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: false
    stdout: SplitParser {
      onRead: data => root.applyThemeLine(data)
    }
    Component.onCompleted: running = true
  }

  // Keeps the shell in sync when the scheme changes outside the control center.
  Process {
    id: themeWatchProc
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true
    stdout: SplitParser {
      onRead: data => root.applyThemeLine(data)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: barVisible

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

          Gammastep {}
          Network {}
          Bluetooth {}
          Volume {}
          Brightness {}
          Battery {}
        }
      }
    }
  }

  Notifications {}

  Variants {
    model: Quickshell.screens

    Menu {
      visible: root.menuVisible
      onCloseRequested: root.menuVisible = false
    }
  }

  Variants {
    model: Quickshell.screens

    Clipboard {
      visible: root.clipboardVisible
      onCloseRequested: root.clipboardVisible = false
    }
  }

  Variants {
    model: Quickshell.screens

    ControlCenter {
      visible: root.controlCenterVisible
      onCloseRequested: root.controlCenterVisible = false
    }
  }

  Wallpapers {}
}
