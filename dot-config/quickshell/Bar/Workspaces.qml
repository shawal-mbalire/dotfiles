import "../Shared"
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 4

  Repeater {
    model: 10

    Rectangle {
      id: workspaceButton

      required property int index
      property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
      property bool isOccupied: workspace !== undefined

      visible: isOccupied || isActive
      implicitWidth: 24
      implicitHeight: 20
      radius: 6
      color: isActive ? Theme.green : Theme.surface1

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on implicitWidth { NumberAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text: workspaceButton.index + 1
        color: workspaceButton.isActive ? Theme.crust : Theme.subtext0
        font {
          family: Theme.font
          pixelSize: 11
          weight: 800
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + (workspaceButton.index + 1))
      }
    }
  }
}
