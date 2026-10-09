import "../Shared"
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 4

  property int workspaceCount: 10

  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1

  // Lua-config Hyprland (0.55+) takes Lua dispatcher expressions; the legacy
  // "workspace N" string is rejected there, so clicks used to do nothing.
  function goTo(id) {
    Hyprland.dispatch(Hyprland.usingLua
      ? "hl.dsp.focus({ workspace = " + id + " })"
      : "workspace " + id)
  }

  Repeater {
    model: root.workspaceCount

    Rectangle {
      id: workspaceButton

      required property int index
      readonly property int workspaceId: index + 1
      readonly property bool isActive: root.focusedId === workspaceId
      readonly property bool isOccupied: Hyprland.workspaces.values.some(ws => ws.id === workspaceId)

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
      TapHandler { onTapped: root.goTo(workspaceButton.workspaceId) }
    }
  }

  // Scroll over the strip to step through workspaces.
  WheelHandler {
    onWheel: event => {
      const step = event.angleDelta.y > 0 ? -1 : 1
      root.goTo(Math.max(1, Math.min(root.workspaceCount, root.focusedId + step)))
    }
  }
}
