import "../../../infra/config"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../Shared"
import "../../../domain/ports"
import "../../../domain/models"

Overlay {
  id: root
  required property AudioPort audioPort
  required property BrightnessPort brightnessPort
  required property BatteryPort batteryPort
  required property NetworkPort networkPort
  required property BluetoothPort bluetoothPort
  required property ColorCorrectionPort colorCorrectionPort
  required property PowerProfilePort powerProfilePort
  required property ColorSchemePort colorSchemePort
  required property MediaPort mediaPort
  property var notificationHistory: []
  readonly property var importantNotifications: NotificationModel.important(notificationHistory)
  signal clearNotificationsRequested()

  property bool showNetworks: false
  property string passwordFor: ""
  property string networkError: ""
  property string expandedCard: ""
  property bool devicesOpen: false

  title: "Control Center"
  shellNamespace: "quickshell:controlcenter"
  showBackground: false
  openOrigin: Item.TopRight
  anchors { top: true; left: false; right: true }
  margins.top: Theme.barHeight
  margins.left: 0; margins.right: 0
  implicitWidth: 400
  implicitHeight: screen.height - margins.top
  mask: Region { item: panel }

  Shortcut { sequence: "Escape"; onActivated: root.closeRequested() }
  Component.onCompleted: colorCorrectionPort.refresh()
  Component.onDestruction: {
    if (showNetworks) networkPort.setScanning(false)
    if (expandedCard === "bt") bluetoothPort.setDiscovering(false)
  }

  onExpandedCardChanged: {
    root.showNetworks = (root.expandedCard === "network")
    if (root.expandedCard === "bt") root.bluetoothPort.setDiscovering(true)
    else if (root.bluetoothPort.discovering) root.bluetoothPort.setDiscovering(false)
  }
  onShowNetworksChanged: {
    if (networkPort) networkPort.setScanning(showNetworks)
    passwordFor = ""; networkError = ""
  }

  function toggleCard(key) { root.expandedCard = root.expandedCard === key ? "" : key }
  function clock(sec) {
    if (!Number.isFinite(sec) || sec <= 0) return "0:00"
    const t = Math.floor(sec), m = Math.floor(t / 60), s = t % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }
  function selectNetwork(entry) {
    networkError = ""
    if (entry.connected) return
    if (entry.secured && !entry.known) { passwordFor = entry.name; return }
    passwordFor = ""; networkPort.connectTo(entry.name)
  }

  Connections {
    target: root.networkPort
    function onConnectionFailed(name, reason) {
      if (reason === "NoSecrets") root.passwordFor = name
      else root.networkError = name + ": " + reason
    }
  }

  // ── Inlined DeviceSelect helper component ─────────────────────────────────
  component DeviceSelect: ColumnLayout {
    id: dsRoot
    property string kind: ""; property string icon: ""; property var items: []; property string currentName: ""
    readonly property string currentLabel: {
      const m = items.find(s => s.name === currentName)
      return m ? m.label : (currentName !== "" ? currentName : "None")
    }
    signal chosen(string name)
    Layout.fillWidth: true; spacing: Theme.spacingSm

    RowLayout {
      Layout.fillWidth: true; spacing: Theme.spacingSm
      Text { text: dsRoot.icon; color: Theme.overlay1; font { family: Theme.nerdFont; pixelSize: 13 } }
      Text { text: dsRoot.kind; color: Theme.overlay1; font { family: Theme.font; pixelSize: 9; weight: 800 } }
      Text {
        Layout.fillWidth: true; text: dsRoot.currentLabel; textFormat: Text.PlainText; color: Theme.subtext0
        font { family: Theme.font; pixelSize: 10; weight: 600 }
        elide: Text.ElideRight
      }
    }

    Column {
      id: dsList; Layout.fillWidth: true; spacing: 2
      Repeater {
        model: dsRoot.items
        delegate: Rectangle {
          id: dsRow; required property var modelData; readonly property bool current: modelData.name === dsRoot.currentName
          width: dsList.width; height: 28; radius: Theme.radiusSm
          color: current ? Theme.surface2 : (dsArea.containsMouse ? Theme.surface1 : "transparent")
          Behavior on color { ColorAnimation { duration: Theme.animFast } }
          Text {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: Theme.padding; rightMargin: Theme.padding }
            text: dsRow.modelData.label; textFormat: Text.PlainText; color: dsRow.current ? Theme.text : Theme.subtext0
            font { family: Theme.font; pixelSize: 11; weight: dsRow.current ? 800 : 600 }
            elide: Text.ElideRight
          }
          MouseArea { id: dsArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dsRoot.chosen(dsRow.modelData.name) }
        }
      }
    }
  }

  Rectangle {
    id: panel
    anchors { left: parent.left; right: parent.right; top: parent.top }
    height: Math.min(col.implicitHeight + Theme.padding * 2, parent.height)
    color: Theme.glass(Theme.base); radius: Theme.radiusLg; border.color: Theme.surface1; border.width: 1; clip: true

    Flickable {
      id: flick
      anchors.fill: parent; contentWidth: width; contentHeight: col.implicitHeight + Theme.padding * 2
      clip: true; boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: col
        x: Theme.padding; y: Theme.padding; width: flick.width - Theme.padding * 2; spacing: Theme.spacing

        // Header
        RowLayout {
          Layout.fillWidth: true; spacing: Theme.spacing
          Text { text: String.fromCodePoint(0xF0493); color: Theme.lavender; font { family: Theme.nerdFont; pixelSize: 16; weight: Theme.fontWeight } }
          Text { text: "Control Center"; color: Theme.text; font { family: Theme.font; pixelSize: 14; weight: 800 } }
          Item { Layout.fillWidth: true }
          Pill {
            icon: root.colorSchemePort.darkMode ? String.fromCodePoint(0xF0594) : String.fromCodePoint(0xF0599)
            label: root.colorSchemePort.darkMode ? "Dark" : "Light"
            checked: root.colorSchemePort.darkMode; checkedColor: Theme.mauve
            onToggled: chk => root.colorSchemePort.setDarkMode(chk)
          }
        }

        // Collapsible Grid
        GridLayout {
          Layout.fillWidth: true; columns: 2; columnSpacing: Theme.spacing; rowSpacing: Theme.spacing

          // Network
          CollapsibleCard {
            Layout.fillWidth: true; expanded: root.expandedCard === "network"; onToggleRequested: root.toggleCard("network")
            icon: String.fromCodePoint(0xF05A9); iconColor: root.networkPort.connected ? Theme.green : Theme.pink; title: "Network"
            summary: !root.networkPort.wifiEnabled ? "Off" : root.networkPort.connected ? root.networkPort.ssid : "Disconnected"

            Pill {
              Layout.fillWidth: true
              icon: root.networkPort.wifiEnabled ? String.fromCodePoint(0xF05A9) : String.fromCodePoint(0xF05AA)
              label: "Wi-Fi"; checked: root.networkPort.wifiEnabled; checkedColor: Theme.green
              onToggled: chk => root.networkPort.setWifiEnabled(chk)
            }
            RowLayout {
              Layout.fillWidth: true; spacing: Theme.spacingSm
              Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: root.networkPort.connected ? Theme.green : Theme.red }
              Text {
                Layout.fillWidth: true; elide: Text.ElideRight; font { family: Theme.font; pixelSize: 12; weight: 600 }
                color: root.networkPort.connected ? Theme.text : Theme.overlay0
                text: !root.networkPort.wifiEnabled ? "Wi-Fi off" : root.networkPort.connected ? root.networkPort.ssid : "Disconnected"
              }
            }
            Text {
              Layout.fillWidth: true; visible: root.networkError !== ""; text: root.networkError
              color: Theme.red
              font { family: Theme.font; pixelSize: 10; weight: 600 }
              wrapMode: Text.Wrap
            }
            Rectangle {
              Layout.fillWidth: true; implicitHeight: 34; visible: root.passwordFor !== ""
              radius: Theme.radiusSm; color: Theme.surface0; border.color: Theme.blue; border.width: 1
              TextInput {
                id: pskInput; anchors.fill: parent; anchors.margins: Theme.paddingSm; verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password; color: Theme.text
                font { family: Theme.font; pixelSize: 12; weight: 600 }
                clip: true
                onVisibleChanged: { text = ""; if (visible) forceActiveFocus() }
                Keys.onPressed: ev => {
                  if (ev.key === Qt.Key_Escape) root.passwordFor = ""
                  else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                    if (text !== "") root.networkPort.connectWithPsk(root.passwordFor, text)
                    root.passwordFor = ""
                  } else return
                  ev.accepted = true
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter; visible: pskInput.text === ""
                  text: "Password for " + root.passwordFor + " — Enter to join"; color: Theme.overlay0; font: pskInput.font; elide: Text.ElideRight; width: parent.width
                }
              }
            }
            Rectangle {
              Layout.fillWidth: true; implicitHeight: root.showNetworks ? Math.min(Math.max(1, root.networkPort.networks.length) * 36 + 8, 216) : 0
              visible: root.showNetworks; radius: Theme.radiusSm; color: Theme.surface0; clip: true
              Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              Text {
                anchors.centerIn: parent; visible: root.networkPort.networks.length === 0
                text: "Scanning…"; color: Theme.overlay0; font { family: Theme.font; pixelSize: 11; weight: 600 }
              }
              ListView {
                anchors.fill: parent; anchors.margins: 4; clip: true; boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: root.networkPort.networks; objectProp: "name" }
                delegate: Rectangle {
                  id: netRow; required property var modelData; width: ListView.view.width; height: 36; radius: 4
                  color: netArea.containsMouse ? Theme.surface1 : "transparent"
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: Theme.spacingSm
                    Text {
                      readonly property int tier: netRow.modelData.signal >= 75 ? 4 : netRow.modelData.signal >= 50 ? 3 : netRow.modelData.signal >= 25 ? 2 : 1
                      text: String.fromCodePoint(0xF091F + (tier - 1) * 3); color: tier >= 3 ? Theme.green : tier === 2 ? Theme.yellow : Theme.red; font { family: Theme.nerdFont; pixelSize: 13 }
                    }
                    Text {
                      text: netRow.modelData.name; textFormat: Text.PlainText; color: netRow.modelData.connected ? Theme.green : Theme.text
                      font { family: Theme.font; pixelSize: 11; weight: netRow.modelData.connected ? 800 : 600 }
                      Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    Text {
                      text: String.fromCodePoint(0xF033E); color: Theme.overlay0
                      font { family: Theme.nerdFont; pixelSize: 11 }
                      visible: netRow.modelData.secured
                    }
                    Text { text: netRow.modelData.connected ? "Connected" : netRow.modelData.signal + "%"; color: Theme.overlay0; font { family: Theme.font; pixelSize: 10; weight: 600 } }
                  }
                  MouseArea { id: netArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectNetwork(netRow.modelData) }
                }
              }
            }
          }

          // Bluetooth
          CollapsibleCard {
            Layout.fillWidth: true; expanded: root.expandedCard === "bt"; onToggleRequested: root.toggleCard("bt"); visible: root.bluetoothPort.available
            icon: root.bluetoothPort.enabled ? String.fromCodePoint(0xF00AF) : String.fromCodePoint(0xF00B2); iconColor: Theme.blue; title: "Bluetooth"
            summary: !root.bluetoothPort.enabled ? "Off" : root.bluetoothPort.connectedName !== "" ? root.bluetoothPort.connectedName : "On"
            RowLayout {
              Layout.fillWidth: true; spacing: Theme.spacingSm
              Pill { Layout.fillWidth: true; icon: String.fromCodePoint(0xF00AF); label: root.bluetoothPort.enabled ? "On" : "Off"; checked: root.bluetoothPort.enabled; checkedColor: Theme.blue; onToggled: chk => root.bluetoothPort.setEnabled(chk) }
              Pill { Layout.fillWidth: true; icon: String.fromCodePoint(0xF0349); label: root.bluetoothPort.discovering ? "Scanning" : "Scan"; checked: root.bluetoothPort.discovering; enabled: root.bluetoothPort.enabled; checkedColor: Theme.blue; onToggled: chk => root.bluetoothPort.setDiscovering(chk) }
            }
            ListView {
              Layout.fillWidth: true; Layout.preferredHeight: Math.min(root.bluetoothPort.devices.length * 34, 170); visible: root.bluetoothPort.devices.length > 0; clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
              model: ScriptModel { values: root.bluetoothPort.devices; objectProp: "address" }
              delegate: Rectangle {
                id: btRow; required property var modelData; readonly property bool busy: modelData.state === "Connecting" || modelData.state === "Disconnecting"
                width: ListView.view.width; height: 34; radius: Theme.radiusSm; color: btRowArea.containsMouse ? Theme.surface2 : Theme.surface1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                MouseArea { id: btRowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btRow.modelData.connected ? root.bluetoothPort.disconnectDevice(btRow.modelData.address) : root.bluetoothPort.connectDevice(btRow.modelData.address) }
                RowLayout {
                  anchors.fill: parent; anchors.margins: 6; spacing: Theme.spacingSm
                  Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: btRow.busy ? Theme.yellow : btRow.modelData.connected ? Theme.blue : Theme.overlay0; Layout.alignment: Qt.AlignVCenter }
                  Text {
                    Layout.fillWidth: true; text: btRow.modelData.name; textFormat: Text.PlainText; color: Theme.text
                    font { family: Theme.font; pixelSize: 11; weight: 600 }
                    elide: Text.ElideRight
                  }
                  Text {
                    text: btRow.modelData.state === "Connecting" ? "Connecting…" : btRow.modelData.state === "Disconnecting" ? "Disconnecting…" : btRow.modelData.connected ? "Connected" : btRow.modelData.paired ? "" : "Pair"
                    color: btRow.busy ? Theme.yellow : Theme.blue
                    font { family: Theme.font; pixelSize: 10; weight: 600 }
                    visible: text !== ""
                  }
                  Text {
                    visible: btRow.modelData.paired; text: "Forget"; color: forgetArea.containsMouse ? Theme.red : Theme.overlay0; font { family: Theme.font; pixelSize: 10; weight: 700 }
                    MouseArea { id: forgetArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.bluetoothPort.forgetDevice(btRow.modelData.address) }
                  }
                }
              }
            }
            Text {
              Layout.fillWidth: true; visible: root.bluetoothPort.devices.length === 0
              text: root.bluetoothPort.discovering ? "Scanning…" : "No devices"; color: Theme.overlay0
              font { family: Theme.font; pixelSize: 11; weight: 600 }
              horizontalAlignment: Text.AlignHCenter
            }
          }

          // Color Correction
          CollapsibleCard {
            Layout.fillWidth: true; expanded: root.expandedCard === "colorCorrection"; onToggleRequested: root.toggleCard("colorCorrection")
            icon: String.fromCodePoint(0xF0594); iconColor: Theme.peach; title: "Color Correction"; summary: root.colorCorrectionPort.active ? "On" : "Off"
            Pill { Layout.fillWidth: true; icon: String.fromCodePoint(0xF0594); label: root.colorCorrectionPort.active ? "On" : "Off"; checked: root.colorCorrectionPort.active; checkedColor: Theme.peach; onToggled: chk => root.colorCorrectionPort.setActive(chk) }
          }

          // Power Profile
          CollapsibleCard {
            Layout.fillWidth: true; expanded: root.expandedCard === "power"; onToggleRequested: root.toggleCard("power")
            icon: String.fromCodePoint(0xF04C5); iconColor: Theme.sapphire; title: "Power"; summary: root.powerProfilePort.profile
            RowLayout {
              Layout.fillWidth: true; spacing: Theme.spacingSm
              Pill { label: "Balanced"; checked: root.powerProfilePort.profile === "Balanced"; checkedColor: Theme.blue; onToggled: root.powerProfilePort.setProfile("Balanced") }
              Pill { visible: root.powerProfilePort.hasPerformance; label: "Performance"; checked: root.powerProfilePort.profile === "Performance"; checkedColor: Theme.peach; onToggled: root.powerProfilePort.setProfile("Performance") }
              Item { Layout.fillWidth: true }
            }
          }

          // Battery
          CollapsibleCard {
            id: batteryTile
            Layout.fillWidth: true; expanded: root.expandedCard === "battery"; onToggleRequested: root.toggleCard("battery"); visible: root.batteryPort.present
            readonly property int level: root.batteryPort.level
            readonly property bool charging: root.batteryPort.charging
            readonly property color levelColor: charging ? Theme.green : level <= 15 ? Theme.red : level <= 30 ? Theme.peach : Theme.green
            icon: charging ? String.fromCodePoint(0xF0084) : level >= 100 ? String.fromCodePoint(0xF0079) : level < 10 ? String.fromCodePoint(0xF0083) : String.fromCodePoint(0xF007A + (Math.floor(level / 10) - 1))
            iconColor: levelColor; title: "Battery"; summary: level + "%"
            RowLayout {
              Layout.fillWidth: true; spacing: Theme.spacing
              Text { text: root.batteryPort.level + "%"; color: Theme.text; font { family: Theme.font; pixelSize: 18; weight: 800 } }
              Item { Layout.fillWidth: true }
              ColumnLayout {
                spacing: 0; Layout.alignment: Qt.AlignRight
                Text {
                  text: root.batteryPort.state; color: Theme.subtext0
                  font { family: Theme.font; pixelSize: 10; weight: 700 }
                  Layout.alignment: Qt.AlignRight
                }
                Text {
                  text: root.batteryPort.timeText; visible: text !== ""; color: Theme.overlay0
                  font { family: Theme.font; pixelSize: 10; weight: 600 }
                  Layout.alignment: Qt.AlignRight
                }
              }
            }
            Rectangle {
              Layout.fillWidth: true; implicitHeight: 6; radius: 3; color: Theme.surface1
              Rectangle { width: parent.width * root.batteryPort.level / 100; height: parent.height; radius: 3; color: batteryTile.levelColor; Behavior on width { NumberAnimation { duration: 250 } } }
            }
          }
        }

        // Media Player
        Card {
          Layout.fillWidth: true; visible: root.mediaPort.available
          icon: String.fromCodePoint(0xF075A); iconColor: Theme.mauve; title: root.mediaPort.playerName !== "" ? root.mediaPort.playerName : "Media"
          Rectangle {
            Layout.fillWidth: true; implicitHeight: 56; radius: Theme.radiusSm; color: Theme.surface1; clip: true
            RowLayout {
              anchors.fill: parent; anchors.margins: Theme.paddingSm; spacing: Theme.spacing
              Rectangle {
                implicitWidth: 42; implicitHeight: 42; radius: Theme.radiusSm; color: Theme.surface2; clip: true
                Image { id: artImage; anchors.fill: parent; source: root.mediaPort.artUrl; fillMode: Image.PreserveAspectCrop; sourceSize.width: 84; sourceSize.height: 84; visible: status === Image.Ready }
                Text {
                  anchors.centerIn: parent; text: String.fromCodePoint(0xF075A); color: Theme.mauve
                  font { family: Theme.nerdFont; pixelSize: 18; weight: Theme.fontWeight }
                  visible: artImage.status !== Image.Ready
                }
              }
              ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                  Layout.fillWidth: true; text: root.mediaPort.title !== "" ? root.mediaPort.title : "Nothing playing"
                  textFormat: Text.PlainText; color: Theme.text
                  font { family: Theme.font; pixelSize: 13; weight: 800 }
                  elide: Text.ElideRight; maximumLineCount: 1
                }
                Text {
                  Layout.fillWidth: true; visible: root.mediaPort.artist !== ""; text: root.mediaPort.artist
                  textFormat: Text.PlainText; color: Theme.subtext0
                  font { family: Theme.font; pixelSize: 11; weight: 600 }
                  elide: Text.ElideRight; maximumLineCount: 1
                }
              }
            }
          }
          RowLayout {
            Layout.fillWidth: true; visible: root.mediaPort.length > 0; spacing: Theme.spacingSm
            Text { text: root.clock(root.mediaPort.position); color: Theme.overlay0; font { family: Theme.font; pixelSize: 9; weight: 600 } }
            Item {
              Layout.fillWidth: true; implicitHeight: 14
              Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.surface1 }
              Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * (root.mediaPort.length > 0 ? Math.min(1, Math.max(0, root.mediaPort.position / root.mediaPort.length)) : 0); height: 4; radius: 2; color: Theme.mauve }
              MouseArea { anchors.fill: parent; enabled: root.mediaPort.canSeek; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onPressed: m => root.mediaPort.seekTo(root.mediaPort.length * Math.max(0, Math.min(1, m.x / width))) }
            }
            Text { text: root.clock(root.mediaPort.length); color: Theme.overlay0; font { family: Theme.font; pixelSize: 9; weight: 600 } }
          }
          RowLayout {
            Layout.fillWidth: true; Layout.topMargin: Theme.spacingSm; spacing: Theme.spacingLg
            Item { Layout.fillWidth: true }
            MediaButton { icon: String.fromCodePoint(0xF04AE); enabled: root.mediaPort.canPrevious; onClicked: root.mediaPort.previous() }
            MediaButton { primary: true; icon: root.mediaPort.playing ? String.fromCodePoint(0xF03E4) : String.fromCodePoint(0xF040A); enabled: root.mediaPort.available; onClicked: root.mediaPort.togglePlaying() }
            MediaButton { icon: String.fromCodePoint(0xF04AD); enabled: root.mediaPort.canNext; onClicked: root.mediaPort.next() }
            Item { Layout.fillWidth: true }
          }
        }

        // Volume & Devices
        Rectangle {
          Layout.fillWidth: true; implicitHeight: volumeCol.implicitHeight + Theme.paddingSm * 2
          radius: Theme.radius; color: Theme.surface0; border.color: Theme.surface1; border.width: 1
          ColumnLayout {
            id: volumeCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.paddingSm }
            spacing: Theme.spacingSm
            RowLayout {
              Layout.fillWidth: true; spacing: Theme.spacing
              Text {
                Layout.alignment: Qt.AlignVCenter; text: root.audioPort.muted ? String.fromCodePoint(0xF075F) : String.fromCodePoint(0xF057E)
                color: root.audioPort.muted ? Theme.overlay1 : Theme.yellow; font { family: Theme.nerdFont; pixelSize: 15; weight: Theme.fontWeight }
                TapHandler { onTapped: root.audioPort.setMuted(!root.audioPort.muted) }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
              }
              Slider { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; value: root.audioPort.volume; barColor: root.audioPort.muted ? Theme.overlay1 : Theme.yellow; onChanged: v => root.audioPort.setVolume(v) }
              Text {
                Layout.alignment: Qt.AlignVCenter; text: String.fromCodePoint(0xF0140); color: Theme.overlay0; font { family: Theme.nerdFont; pixelSize: 12 }
                rotation: root.devicesOpen ? 180 : 0; Behavior on rotation { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeOut } }
                TapHandler { onTapped: root.devicesOpen = !root.devicesOpen }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
              }
            }
            Item {
              id: devicesBox; Layout.fillWidth: true; clip: true; implicitHeight: root.devicesOpen ? devicesCol.implicitHeight : 0
              Behavior on implicitHeight { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeOut } }
              ColumnLayout {
                id: devicesCol; width: parent.width; spacing: Theme.spacing
                DeviceSelect { kind: "OUTPUT"; icon: String.fromCodePoint(0xF04C3); items: root.audioPort.sinks; currentName: root.audioPort.sinkName; onChosen: nm => root.audioPort.setDefaultSink(nm) }
                DeviceSelect { kind: "INPUT"; icon: String.fromCodePoint(0xF036C); items: root.audioPort.sources; currentName: root.audioPort.sourceName; onChosen: nm => root.audioPort.setDefaultSource(nm) }
              }
            }
          }
        }

        // Brightness
        Rectangle {
          Layout.fillWidth: true; visible: root.brightnessPort.available; implicitHeight: 34; radius: Theme.radius
          color: Theme.surface0; border.color: Theme.surface1; border.width: 1
          RowLayout {
            anchors { fill: parent; leftMargin: Theme.padding; rightMargin: Theme.padding }
            spacing: Theme.spacing
            Text {
              Layout.alignment: Qt.AlignVCenter
              text: root.brightnessPort.percent === 0 ? String.fromCodePoint(0xF00DA) : root.brightnessPort.percent < 34 ? String.fromCodePoint(0xF00DC) : root.brightnessPort.percent < 67 ? String.fromCodePoint(0xF00DE) : String.fromCodePoint(0xF00E0)
              color: Theme.peach; font { family: Theme.nerdFont; pixelSize: 15; weight: Theme.fontWeight }
            }
            Slider { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; value: root.brightnessPort.percent; barColor: Theme.peach; onChanged: v => root.brightnessPort.setPercent(v) }
          }
        }

        // Notifications
        CollapsibleCard {
          Layout.fillWidth: true; expanded: root.expandedCard === "notif"; onToggleRequested: root.toggleCard("notif")
          icon: String.fromCodePoint(0xF009A); iconColor: Theme.mauve; title: "Notifications"
          summary: root.importantNotifications.length > 0 ? root.importantNotifications.length + " important" : "None"
          RowLayout {
            Layout.fillWidth: true; visible: root.importantNotifications.length > 0; spacing: Theme.spacing
            Text { text: root.importantNotifications.length + " important"; color: Theme.overlay0; font { family: Theme.font; pixelSize: 10; weight: 600 } }
            Item { Layout.fillWidth: true }
            Text {
              text: "Clear"; color: clearArea.containsMouse ? Theme.red : Theme.overlay0; font { family: Theme.font; pixelSize: 10; weight: 700 }
              MouseArea { id: clearArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearNotificationsRequested() }
            }
          }
          ListView {
            Layout.fillWidth: true; Layout.preferredHeight: Math.min(root.importantNotifications.length * 42, 168); visible: root.importantNotifications.length > 0
            clip: true; spacing: 4; boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel { values: root.importantNotifications; objectProp: "key" }
            delegate: Rectangle {
              id: historyRow; required property var modelData; width: ListView.view.width; height: 38; radius: Theme.radiusSm; color: Theme.surface1
              RowLayout {
                anchors.fill: parent; anchors.margins: Theme.paddingSm; spacing: Theme.spacingSm
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: historyRow.modelData.critical ? Theme.red : Theme.blue }
                ColumnLayout {
                  spacing: 0; Layout.fillWidth: true
                  Text {
                    text: historyRow.modelData.summary; textFormat: Text.PlainText; color: Theme.text
                    font { family: Theme.font; pixelSize: 11; weight: 700 }
                    elide: Text.ElideRight; Layout.fillWidth: true
                  }
                  Text {
                    text: historyRow.modelData.body !== "" ? historyRow.modelData.body : historyRow.modelData.appName; textFormat: Text.PlainText; color: Theme.overlay0
                    font { family: Theme.font; pixelSize: 9; weight: 600 }
                    elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true; visible: text !== ""
                  }
                }
                Text { text: Qt.formatTime(historyRow.modelData.receivedAt, "HH:mm"); color: Theme.overlay0; font { family: Theme.font; pixelSize: 9; weight: 600 } }
              }
            }
          }
          Text {
            text: "No important notifications"; color: Theme.subtext0
            font { family: Theme.font; pixelSize: 11; weight: 600 }
            visible: root.importantNotifications.length === 0
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
