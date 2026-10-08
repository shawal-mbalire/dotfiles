import "../Shared"
import "../domain/ports"
import "../domain/models/clipboard.js" as Clip
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// View only: history lives in the ClipboardPort adapter, so it survives this
// overlay being destroyed on close and is shared across screens.
//   Enter / click      copy and close
//   Delete / right-click  remove the entry
//   Up/Down, Tab, Ctrl+J/K  move
Overlay {
  id: root

  required property ClipboardPort clipboardPort

  title: "Clipboard"
  shellNamespace: "quickshell:clipboard"
  implicitWidth: 420
  implicitHeight: 460

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property int selectedIndex: 0
  readonly property var results: {
    const q = input.text.trim().toLowerCase()
    const all = clipboardPort.history
    return q === "" ? all : all.filter(t => t.toLowerCase().includes(q))
  }

  onResultsChanged: selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1))

  readonly property string statusText: {
    if (clipboardPort.state === "unavailable") return "Clipboard watcher is not running (is wl-clipboard installed?)"
    if (clipboardPort.history.length > 0) return "No matches"
    return "Nothing copied yet"
  }

  function move(delta) {
    if (results.length === 0) return
    selectedIndex = (selectedIndex + delta + results.length) % results.length
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function pick(index) {
    const text = results[index]
    if (text === undefined) return
    clipboardPort.copy(text)
    closeRequested()
  }

  function removeAt(index) {
    const text = results[index]
    if (text !== undefined) clipboardPort.remove(text)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Theme.paddingLg
    spacing: Theme.spacing

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 40
      radius: Theme.radius
      color: Theme.surface0
      border.color: input.activeFocus ? Theme.blue : Theme.surface1
      border.width: 1

      Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        spacing: Theme.spacing

        Text {
          text: String.fromCodePoint(0xF014C)
          color: Theme.overlay1
          font { family: Theme.nerdFont; pixelSize: 16 }
        }

        TextInput {
          id: input
          Layout.fillWidth: true
          color: Theme.text
          selectionColor: Theme.blue
          selectedTextColor: Theme.crust
          font { family: Theme.font; pixelSize: 14; weight: 600 }
          clip: true
          focus: true
          Component.onCompleted: forceActiveFocus()

          Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) root.move(1)
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) root.move(-1)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.pick(root.selectedIndex)
            else if (event.key === Qt.Key_Delete) root.removeAt(root.selectedIndex)
            else if (event.key === Qt.Key_Escape) root.closeRequested()
            else return
            event.accepted = true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: "Search clipboard…"
            color: Theme.overlay0
            font: input.font
          }
        }

        Text {
          visible: root.clipboardPort.history.length > 0
          text: "Clear"
          color: clearHover.hovered ? Theme.red : Theme.overlay0
          font { family: Theme.font; pixelSize: 11; weight: 700 }

          Behavior on color { ColorAnimation { duration: Theme.animFast } }

          HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.clipboardPort.clear() }
        }
      }
    }

    ListView {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 2
      boundsBehavior: Flickable.StopAtBounds
      currentIndex: root.selectedIndex

      highlightFollowsCurrentItem: true
      highlightMoveDuration: Theme.animFast
      highlightMoveVelocity: -1
      highlight: Rectangle {
        radius: Theme.radiusSm
        color: Theme.surface1
      }

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
        NumberAnimation { property: "x"; from: -12; to: 0; duration: Theme.animNormal; easing.type: Theme.easeOut }
      }
      remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.animFast; easing.type: Theme.easeIn }
        NumberAnimation { property: "x"; to: 24; duration: Theme.animFast; easing.type: Theme.easeIn }
      }
      displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Theme.animNormal; easing.type: Theme.easeOut }
        NumberAnimation { property: "opacity"; to: 1; duration: Theme.animFast }
      }

      // Diffed by value, so filtering and new copies animate instead of
      // rebuilding the whole list.
      model: ScriptModel { values: root.results }

      delegate: Item {
        id: row
        required property string modelData
        required property int index

        width: ListView.view.width
        height: 40

        Text {
          anchors.fill: parent
          anchors.leftMargin: Theme.padding
          anchors.rightMargin: Theme.padding
          text: Clip.preview(row.modelData)
          textFormat: Text.PlainText
          color: Theme.text
          font { family: Theme.font; pixelSize: 12; weight: 600 }
          elide: Text.ElideRight
          verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onEntered: root.selectedIndex = row.index
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.removeAt(row.index)
            else root.pick(row.index)
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.results.length === 0

      Text {
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: root.statusText
        color: Theme.overlay0
        font { family: Theme.font; pixelSize: 12; weight: 600 }
      }
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: "Enter copy · Del remove · Esc close"
      color: Theme.overlay0
      font { family: Theme.font; pixelSize: 10; weight: 600 }
    }
  }
}
