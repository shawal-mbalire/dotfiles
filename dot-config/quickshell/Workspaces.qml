import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 5

  Repeater {
    model: 10
     
    // button
    Rectangle {
      id: workspaceButton
      
      required property int index
      property var workspace: Hyprland.workspaces.values.find(workspace => workspace.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
      
      implicitWidth: label.implicitWidth + 15
      implicitHeight: label.implicitHeight + 5
      radius: 2
      color: isActive ? "#1d3631" : (workspace ? "#0f211f" : "transparent")

      // animation
      Behavior on color {
        ColorAnimation { duration: 150}
      }

      // text
      Text {
        id: label
        anchors.centerIn: parent
        text: workspaceButton.index + 1
        color
            : workspaceButton.isActive ? "#3dd1b0" 
            : (workspaceButton.workspace ? "#f5e2c5" : "#5a4d3e")
        font {
          family: "Comfortaa"
          pixelSize: 15
          weight: 1000
        }
      }

      // click event
      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + "})")
      }
    }
  }
}

