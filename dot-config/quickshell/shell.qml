import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import QtQuick

ShellRoot {
  // Catppuccin Mocha
  property color colorRosewater: "#f5e0dc"
  property color colorFlamingo: "#f2cdcd"
  property color colorPink: "#f5c2e7"
  property color colorMauve: "#cba6f7"
  property color colorRed: "#f38ba8"
  property color colorMaroon: "#eba0ac"
  property color colorPeach: "#fab387"
  property color colorYellow: "#f9e2af"
  property color colorGreen: "#a6e3a1"
  property color colorTeal: "#94e2d5"
  property color colorSky: "#89dceb"
  property color colorSapphire: "#74c7ec"
  property color colorBlue: "#89b4fa"
  property color colorLavender: "#b4befe"
  property color colorText: "#cdd6f4"
  property color colorSubtext1: "#bac2de"
  property color colorSubtext0: "#a6adc8"
  property color colorOverlay2: "#9399b2"
  property color colorOverlay1: "#7f849c"
  property color colorOverlay0: "#6c7086"
  property color colorSurface2: "#585b70"
  property color colorSurface1: "#45475a"
  property color colorSurface0: "#313244"
  property color colorBase: "#1e1e2e"
  property color colorMantle: "#181825"
  property color colorCrust: "#11111b"
  property string themeFont: "Comfortaa"
  property int themeFontSize: 15
  property int themeFontWeight: 1000

  property bool barVisible: true

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
      color: colorMantle

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Workspaces {}
        Item { Layout.fillWidth: true }

        Clock {}
        Item { Layout.fillWidth: true }

        RowLayout {
          spacing: 20
          Network {}
          Volume {}
          Battery {}
        }
      }

      IpcHandler {
        target: "bar"
        function toggle(): void { barVisible = !barVisible }
      }
    }
  }

  Clipboard {}
  ControlCenter {}
  Menu {}
}
