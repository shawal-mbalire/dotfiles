import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
  id: root

  property var notifications: []
  property int maxVisible: 5

  anchors {
    top: true
    right: true
  }

  margins.top: 8
  margins.right: 8

  width: 320
  height: Math.min(notifications.length * 70 + 20, maxVisible * 70 + 20)
  color: "transparent"

  WlrLayershell.namespace: "quickshell:notifications"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusiveZone: 0

  visible: notifications.length > 0

  NotificationServer {
    id: notificationServer

    onNotification: function(notification) {
      notification.dismiss()

      const entry = {
        id: Date.now(),
        appIcon: notification.appIcon ?? "",
        appName: notification.appName ?? "Unknown",
        summary: notification.summary ?? "",
        body: notification.body ?? "",
        urgency: notification.urgency,
        timestamp: Date.now()
      }

      root.notifications.push(entry)
      root.notifications = root.notifications.slice(-root.maxVisible)

      dismissTimer.restart()
    }
  }

  Timer {
    id: dismissTimer
    interval: 5000
    onTriggered: {
      if (root.notifications.length > 0) {
        root.notifications.shift()
        root.notifications = root.notifications
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: colorBase
    radius: 10

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 6

      Repeater {
        model: root.notifications

        Rectangle {
          required property var modelData
          required property int index

          Layout.fillWidth: true
          height: 54
          radius: 8
          color: modelData.urgency === 1 ? colorSurface1 : colorSurface0
          border.color: modelData.urgency === 1 ? colorRed : colorSurface1
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Rectangle {
              implicitWidth: 32
              implicitHeight: 32
              radius: 6
              color: colorSurface1

              Image {
                anchors.centerIn: parent
                source: modelData.appIcon
                width: 20
                height: 20
                sourceSize: Qt.size(20, 20)
                visible: status === Image.Ready
              }

              Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF0494)
                color: colorOverlay0
                font { pixelSize: 16 }
                visible: modelData.appIcon === ""
              }
            }

            ColumnLayout {
              spacing: 2
              Layout.fillWidth: true

              Text {
                text: modelData.summary
                color: colorText
                font { family: themeFont; pixelSize: 12; weight: 800 }
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: modelData.body
                color: colorOverlay0
                font { family: themeFont; pixelSize: 10; weight: 600 }
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }
            }

            Rectangle {
              implicitWidth: 20
              implicitHeight: 20
              radius: 10
              color: dismissArea.containsMouse ? colorRed : "transparent"

              Text {
                anchors.centerIn: parent
                text: "\u00D7"
                color: colorText
                font { pixelSize: 14; weight: 800 }
              }

              MouseArea {
                id: dismissArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  root.notifications.splice(index, 1)
                  root.notifications = root.notifications
                }
              }
            }
          }
        }
      }
    }
  }
}
