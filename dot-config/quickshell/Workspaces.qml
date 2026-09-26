import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 5

  Repeater {
    model: 10

    Rectangle {
      id: workspaceButton

      required property int index
      property var workspace: Hyprland.workspaces.values.find(workspace => workspace.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

      implicitWidth: label.implicitWidth + 15
      implicitHeight: label.implicitHeight + 5
      radius: 2
      color: isActive ? colorSurface1 : (workspace ? colorSurface0 : "transparent")

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: workspaceButton.index + 1
        color: workspaceButton.isActive ? colorGreen
             : (workspaceButton.workspace ? colorText : colorOverlay0)
        font {
          family: themeFont
          pixelSize: themeFontSize
          weight: themeFontWeight
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
      }
    }
  }
}
