import Quickshell
import Quickshell
import QtQuick.Layouts
import QtQuick

ShellRoot {
  Variants { // for multi monitors
    model: Quickshell.screens
 
    // top bar
    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 30 
      color: "#040e0d"
    
      RowLayout{
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        // left
        Workspaces {}
        Item {Layout.fillWidth: true}

        // Center
        RowLayout{
          anchors.centerIn: parent
          Clock {}
        }
        Item {Layout.fillWidth: true}

        // right
        RowLayout {
          spacing : 20

          // Brightness {}
          Network {}
          Volume {}
          Battery {}
        }
      }
    }
  }
}
