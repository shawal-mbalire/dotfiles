import "../../../infra/config"
import "../../../domain/constants"
import "../../../domain/ports"
import "../Shared"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 4

  required property WorkspacePort workspacePort

  readonly property int activeId: WorkspacePolicy.activeId(workspacePort.focusedId)

  Repeater {
    model: root.workspacePort.count

    Rectangle {
      id: workspaceButton

      required property int index
      readonly property int workspaceId: index + 1
      readonly property bool isActive: root.activeId === workspaceId
      readonly property bool isOccupied: root.workspacePort.occupiedIds.indexOf(workspaceId) >= 0

      visible: isOccupied || isActive
      implicitWidth: isActive ? 32 : 22
      implicitHeight: 20
      radius: 6
      color: isActive ? Theme.green : hover.hovered ? Theme.surface2 : Theme.surface1

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

      // Center by aligning inside the whole button box rather than by the
      // text's own measured width/height, so it stays centered across the
      // animated active/inactive width and any font metric quirks.
      Text {
        anchors.fill: parent
        text: workspaceButton.workspaceId
        color: workspaceButton.isActive ? Theme.crust : Theme.subtext0
        font { family: Theme.font; pixelSize: 11; weight: 800 }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.workspacePort.focus(workspaceButton.workspaceId) }
    }
  }

  // Scroll over the strip to step through workspaces.
  WheelHandler {
    onWheel: event => {
      const step = event.angleDelta.y > 0 ? -1 : 1
      root.workspacePort.focus(WorkspacePolicy.stepTarget(root.workspacePort.focusedId, step))
    }
  }
}
