import "../Shared"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Overlay {
  id: root
  title: "Notifications"
  shellNamespace: "quickshell:notifications"
  implicitWidth: 320
  implicitHeight: Math.min(listView.contentHeight + Theme.padding * 2, maxVisible * 100 + Theme.padding * 2)

  property var notifications: []
  property int maxVisible: 5
  property int nextKey: 1
  property double now: Date.now()
  property int normalTimeout: 5000
  property int lowTimeout: 4000
  property int maxTimeout: 10000

  anchors {
    top: true
    bottom: false
    left: true
    right: false
  }

  margins.top: 8
  margins.left: 8

  visible: notifications.length > 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  function timeoutFor(notification) {
    if (notification.urgency === NotificationUrgency.Critical) return 0
    const timeout = notification.expireTimeout
    let ms
    if (timeout <= 0) ms = notification.urgency === NotificationUrgency.Low ? lowTimeout : normalTimeout
    else if (timeout <= 60) ms = timeout * 1000
    else ms = timeout
    return Math.min(ms, maxTimeout)
  }

  function add(notification) {
    const durationMs = timeoutFor(notification)
    const key = nextKey++
    const entry = {
      key: key,
      ref: notification,
      appName: notification.appName || "Unknown",
      appIcon: notification.appIcon || "",
      summary: notification.summary || "",
      body: notification.body || "",
      urgency: notification.urgency,
      isTransient: notification.transient,
      durationMs: durationMs,
      expiresAt: durationMs > 0 ? Date.now() + durationMs : 0,
      remainingMs: durationMs,
      paused: false
    }

    const next = [...notifications, entry]
    const overflow = next.slice(0, next.length - maxVisible)
    notifications = next.slice(-maxVisible)
    overflow.forEach(item => callRef(item.ref, "expire"))

    NotificationBridge.notified(entry.key, entry.appName, entry.summary, entry.body, entry.urgency, entry.isTransient)
    return key
  }

  function callRef(ref, method) {
    if (ref && typeof ref[method] === "function") ref[method]()
  }

  function closeEntry(key, userAction) {
    const entry = notifications.find(item => item.key === key)
    if (!entry) return
    notifications = notifications.filter(item => item.key !== key)
    callRef(entry.ref, userAction ? "dismiss" : "expire")
  }

  function pause(key) {
    const entry = notifications.find(item => item.key === key)
    if (!entry || entry.paused || entry.expiresAt <= 0) return
    entry.remainingMs = Math.max(0, entry.expiresAt - Date.now())
    entry.paused = true
  }

  function resume(key) {
    const entry = notifications.find(item => item.key === key)
    if (!entry || !entry.paused) return
    entry.expiresAt = Date.now() + entry.remainingMs
    entry.paused = false
  }

  NotificationServer {
    id: notificationServer
    keepOnReload: true

    onNotification: function(notification) {
      notification.tracked = true
      const key = root.add(notification)
      notification.closed.connect(() => {
        root.notifications = root.notifications.filter(item => item.key !== key)
      })
    }
  }

  function clearAll() {
    notifications.slice().forEach(item => closeEntry(item.key, true))
  }

  IpcHandler {
    target: "notifications"
    function dismissAll(): void { root.clearAll() }
  }

  Timer {
    interval: 100
    running: root.notifications.length > 0
    repeat: true
    onTriggered: {
      root.now = Date.now()
      root.notifications
        .filter(item => !item.paused && item.expiresAt > 0 && root.now >= item.expiresAt)
        .forEach(item => root.closeEntry(item.key, false))
    }
  }

  ListView {
    id: listView
    anchors.fill: parent
    anchors.margins: Theme.padding
    clip: true
    spacing: Theme.spacing

    model: ScriptModel {
      values: root.notifications
      objectProp: "key"
    }

    delegate: Rectangle {
      id: delegateRoot
      required property var modelData

      height: implicitHeight
      implicitHeight: Theme.padding + contentRow.implicitHeight
        + (progressTrack.visible ? Theme.spacing + progressTrack.height + Theme.paddingSm : Theme.padding)
      radius: Theme.radius
      color: critical ? Theme.surface1 : Theme.surface0
      border.color: critical ? Theme.red : Theme.surface1
      border.width: 1
      clip: true

      FontMetrics {
        id: bodyMetrics
        font { family: Theme.font; pixelSize: 11; weight: 600 }
      }

      property bool critical: modelData.urgency === NotificationUrgency.Critical
      readonly property url iconSource: {
        const icon = modelData.appIcon
        if (!icon) return ""
        if (icon.startsWith("/") || icon.includes("://")) return icon
        return "image://icon/" + icon
      }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onContainsMouseChanged: {
          if (containsMouse) root.pause(modelData.key)
          else if (!closeHover.containsMouse) root.resume(modelData.key)
        }

        onClicked: {
          const actions = modelData.ref.actions
          let defaultAction = null
          for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default") {
              defaultAction = actions[i]
              break
            }
          }
          if (defaultAction) defaultAction.invoke()
          else root.closeEntry(modelData.key, true)
        }
      }

      Rectangle {
        id: progressTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        anchors.bottomMargin: Theme.paddingSm
        height: 4
        radius: 2
        color: Theme.surface1
        visible: modelData.durationMs > 0

        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, (modelData.expiresAt - root.now) / modelData.durationMs))
          height: parent.height
          radius: parent.radius
          color: Theme.blue

          Behavior on width { NumberAnimation { duration: 100 } }
        }
      }

      RowLayout {
        id: contentRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.padding
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        spacing: Theme.spacingLg

        Rectangle {
          implicitWidth: 40
          implicitHeight: 40
          radius: Theme.radiusSm
          color: Theme.surface1
          Layout.alignment: Qt.AlignVCenter

          Image {
            id: appImage
            anchors.centerIn: parent
            source: delegateRoot.iconSource
            width: 24
            height: 24
            sourceSize: Qt.size(24, 24)
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: "\uf0494"
            color: Theme.overlay0
            font { family: Theme.nerdFont; pixelSize: 20; weight: Theme.fontWeight }
            visible: appImage.status !== Image.Ready
          }
        }

        ColumnLayout {
          spacing: Theme.spacingSm
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter

          Text {
            text: modelData.summary
            textFormat: Text.PlainText
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; weight: 800 }
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Text {
            text: modelData.body
            textFormat: Text.PlainText
            color: Theme.overlay0
            font { family: Theme.font; pixelSize: 11; weight: 600 }
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 3
            Layout.fillWidth: true
            Layout.maximumHeight: bodyMetrics.height * 3 + 4
            visible: text !== ""
          }
        }

        Rectangle {
          implicitWidth: 24
          implicitHeight: 24
          radius: 12
          color: closeHover.containsMouse ? Theme.red : "transparent"
          Layout.alignment: Qt.AlignVCenter

          Text {
            anchors.centerIn: parent
            text: "\u00D7"
            color: Theme.text
            font { pixelSize: 15; weight: 800 }
          }

          MouseArea {
            id: closeHover
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true

            onContainsMouseChanged: {
              if (containsMouse) root.pause(modelData.key)
              else if (!hoverArea.containsMouse) root.resume(modelData.key)
            }

            onClicked: root.closeEntry(modelData.key, true)
          }
        }
      }
    }
  }
}
