import "../../../infra/config"
import "../../../domain/ports"
import "../Shared"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Overlay {
  id: root
  title: "Notifications"
  shellNamespace: "quickshell:notifications"
  dismissOnOutsideClick: false
  showBackground: false
  implicitWidth: 360
  // Sized from a non-virtualized Column. A ListView here sized the window from
  // its own contentHeight, which stayed 0 because a 0px-tall ListView never
  // creates delegates — popups showed up empty with no close button.
  implicitHeight: Math.max(1, stack.implicitHeight)

  required property NotificationFeedPort feedPort

  anchors {
    top: true
    bottom: false
    left: true
    right: false
  }

  margins.top: 8
  margins.left: 8

  visible: feedPort.popups.length > 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  IpcHandler {
    target: "notifications"
    function dismissAll(): void { root.feedPort.dismissAll() }
    function clearHistory(): void { root.feedPort.clearHistory() }
  }

  Column {
    id: stack
    width: root.width
    spacing: Theme.spacing

    add: Transition {
      NumberAnimation { property: "x"; from: -root.width * 0.6; to: 0; duration: Theme.animSlow; easing.type: Theme.easeOut }
      NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.easeOut }
    }
    move: Transition {
      NumberAnimation { property: "y"; duration: Theme.animNormal; easing.type: Theme.easeOut }
    }

    Repeater {
      model: ScriptModel {
        values: root.feedPort.popups
        objectProp: "key"
      }

      delegate: Rectangle {
        id: card
        required property var modelData

        readonly property bool critical: modelData.critical
        readonly property bool timed: modelData.durationMs > 0
        readonly property url iconSource: {
          if (modelData.image) return modelData.image
          const icon = modelData.appIcon
          if (!icon) return ""
          if (icon.startsWith("/") || icon.includes("://")) return icon
          return Quickshell.iconPath(icon, true)
        }

        // 1 -> 0 over the timeout. A per-card animation replaces the old
        // shell-wide 100ms Timer that re-evaluated every card's bindings.
        property real remaining: 1

        width: stack.width
        implicitHeight: content.implicitHeight + Theme.padding * 2
        radius: Theme.radius
        color: critical ? Theme.surface1 : Theme.base
        border.color: critical ? Theme.red : Theme.surface1
        border.width: 1

        readonly property bool isLeaving: modelData.phase !== "shown"
        onIsLeavingChanged: if (isLeaving) exitAnim.start()

        ParallelAnimation {
          id: exitAnim
          NumberAnimation { target: card; property: "x"; to: -card.width * 0.6; duration: Theme.animNormal; easing.type: Theme.easeIn }
          NumberAnimation { target: card; property: "opacity"; to: 0; duration: Theme.animNormal; easing.type: Theme.easeIn }
          onFinished: root.feedPort.finish(card.modelData.key)
        }

        NumberAnimation on remaining {
          from: 1
          to: 0
          duration: Math.max(1, card.modelData.durationMs)
          running: card.timed && !card.isLeaving
          paused: running && hover.hovered
          onFinished: root.feedPort.expire(card.modelData.key)
        }

        HoverHandler { id: hover }

        // Left: default action (or dismiss). Right/middle: dismiss.
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) root.feedPort.invoke(card.modelData.key, "default")
            else root.feedPort.dismiss(card.modelData.key)
          }
        }

        ColumnLayout {
          id: content
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: Theme.padding
          spacing: Theme.spacing

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingLg

            Rectangle {
              implicitWidth: 40
              implicitHeight: 40
              radius: Theme.radiusSm
              color: Theme.surface0
              Layout.alignment: Qt.AlignTop

              Image {
                id: appImage
                anchors.fill: parent
                anchors.margins: card.modelData.image ? 0 : 8
                source: card.iconSource
                sourceSize: Qt.size(80, 80)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
              }

              Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF009A)
                color: card.critical ? Theme.red : Theme.overlay1
                font { family: Theme.nerdFont; pixelSize: 20 }
                visible: appImage.status !== Image.Ready
              }
            }

            ColumnLayout {
              spacing: 2
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignTop

              Text {
                text: card.modelData.appName
                textFormat: Text.PlainText
                color: Theme.overlay1
                font { family: Theme.font; pixelSize: 10; weight: 700 }
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: card.modelData.summary
                textFormat: Text.PlainText
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; weight: 800 }
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: card.modelData.body
                textFormat: Text.PlainText
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 11; weight: 600 }
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }
            }

            Rectangle {
              implicitWidth: 22
              implicitHeight: 22
              radius: 11
              color: closeArea.containsMouse ? Theme.red : Theme.surface0
              Layout.alignment: Qt.AlignTop

              Text {
                anchors.centerIn: parent
                text: "×"
                color: closeArea.containsMouse ? Theme.crust : Theme.text
                font { family: Theme.font; pixelSize: 14; weight: 800 }
              }

              MouseArea {
                id: closeArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.feedPort.dismiss(card.modelData.key)
              }
            }
          }

          Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingSm
            visible: card.modelData.actions.length > 0

            Repeater {
              model: card.modelData.actions

              delegate: Rectangle {
                id: actionButton
                required property var modelData
                implicitWidth: actionLabel.implicitWidth + Theme.padding * 2
                implicitHeight: 26
                radius: height / 2
                color: actionArea.containsMouse ? Theme.surface2 : Theme.surface1

                Text {
                  id: actionLabel
                  anchors.centerIn: parent
                  text: actionButton.modelData.text
                  textFormat: Text.PlainText
                  color: Theme.text
                  font { family: Theme.font; pixelSize: 11; weight: 700 }
                }

                MouseArea {
                  id: actionArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.feedPort.invoke(card.modelData.key, actionButton.modelData.identifier)
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 2
            color: Theme.surface1
            visible: card.timed

            Rectangle {
              width: parent.width * card.remaining
              height: parent.height
              radius: parent.radius
              color: card.critical ? Theme.red : Theme.blue
            }
          }
        }
      }
    }
  }
}
