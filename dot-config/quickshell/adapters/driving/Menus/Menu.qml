import "../../../infra/config"
import "../Shared"
import "../../../domain/ports"
import "../../../domain/models"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Created on demand by shell.qml (LazyLoader) and destroyed on close, so every
// open starts from a clean query with no reset bookkeeping.
Overlay {
  id: root

  required property LaunchPort launchPort

  title: "Menu"
  shellNamespace: "quickshell:menu"
  implicitWidth: 460
  implicitHeight: 440

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property int selectedIndex: 0
  readonly property var results: AppSearch.filter(launchPort.apps, input.text)

  onResultsChanged: selectedIndex = 0

  function move(delta) {
    if (results.length === 0) return
    selectedIndex = (selectedIndex + delta + results.length) % results.length
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function launch(index) {
    const app = results[index]
    if (!app) return
    if (launchPort.launch(app.id)) closeRequested()
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

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        spacing: Theme.spacing

        Text {
          text: String.fromCodePoint(0xF0349)
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
            else if (event.key === Qt.Key_PageDown) root.move(5)
            else if (event.key === Qt.Key_PageUp) root.move(-5)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launch(root.selectedIndex)
            else if (event.key === Qt.Key_Escape) root.closeRequested()
            else return
            event.accepted = true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: "Search apps…"
            color: Theme.overlay0
            font: input.font
          }
        }

        Text {
          text: root.results.length
          color: Theme.overlay0
          font { family: Theme.font; pixelSize: 11; weight: 700 }
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
      visible: root.results.length > 0
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
      }
      displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Theme.animNormal; easing.type: Theme.easeOut }
        NumberAnimation { property: "opacity"; to: 1; duration: Theme.animFast }
      }

      model: ScriptModel {
        values: root.results
        objectProp: "id"
      }

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index
        readonly property bool selected: index === root.selectedIndex
        readonly property string iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""

        width: ListView.view.width
        height: 46
        radius: Theme.radiusSm
        color: "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Theme.paddingSm
          anchors.rightMargin: Theme.paddingSm
          spacing: Theme.spacingLg

          Item {
            implicitWidth: 28
            implicitHeight: 28

            IconImage {
              id: appIcon
              anchors.fill: parent
              source: row.iconSource
              asynchronous: true
              visible: row.iconSource !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: !appIcon.visible
              text: String.fromCodePoint(0xF08C6)
              color: Theme.overlay1
              font { family: Theme.nerdFont; pixelSize: 20 }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              text: row.modelData.name
              textFormat: Text.PlainText
              color: Theme.text
              font { family: Theme.font; pixelSize: 13; weight: 700 }
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: row.modelData.genericName || row.modelData.comment
              textFormat: Text.PlainText
              color: Theme.overlay1
              font { family: Theme.font; pixelSize: 10; weight: 600 }
              elide: Text.ElideRight
              Layout.fillWidth: true
              visible: text !== ""
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.selectedIndex = row.index
          onClicked: root.launch(row.index)
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.results.length === 0

      Text {
        anchors.centerIn: parent
        text: root.launchPort.apps.length === 0 ? "No applications found" : "No matches"
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 12; weight: 600 }
      }
    }
  }
}
