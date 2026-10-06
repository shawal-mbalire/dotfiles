import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "../Shared"

PanelWindow {
  id: root
  required property var modelData

  screen: modelData

  signal closeRequested()

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool sinkReady: sink !== null && sink.ready
  readonly property int volume: sinkReady ? Math.round(sink.audio.volume * 100) : 0

  PwObjectTracker {
    objects: [root.sink]
  }

  readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  readonly property var activeNetwork: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
  readonly property string networkName: activeNetwork ? activeNetwork.name : ""
  readonly property bool networkConnected: activeNetwork !== null
  readonly property bool wifiEnabled: Networking.wifiEnabled

  property bool bluetoothEnabled: false
  property var networks: []
  property var pendingNetworks: []
  property bool showNetworks: false
  property bool nightLight: false

  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery !== null && battery.ready && battery.isLaptopBattery
  readonly property int batteryLevel: battery !== null ? Math.round(battery.percentage * 100) : 0
  readonly property bool charging: battery !== null && battery.state === UPowerDeviceState.Charging

  readonly property int brightness: brightValue.value

  readonly property string batteryState: {
    if (charging) return "Charging"
    if (battery !== null && battery.state === UPowerDeviceState.Discharging) return "Discharging"
    if (battery !== null && battery.state === UPowerDeviceState.FullyCharged) return "Full"
    if (battery !== null && battery.state === UPowerDeviceState.PendingCharge) return "Plugged in"
    return "Unknown"
  }

  readonly property string batteryTime: {
    if (battery === null) return ""
    const s = charging ? battery.timeToFull : battery.timeToEmpty
    if (s <= 0) return ""
    const h = Math.floor(s / 3600)
    const m = Math.round((s % 3600) / 60)
    const t = h > 0 ? h + "h " + m + "m" : m + "m"
    return charging ? t + " to full" : t + " left"
  }

  anchors {
    top: true
    right: true
  }

  margins.top: 40
  margins.right: 8

  implicitWidth: 300
  implicitHeight: Math.min(col.implicitHeight + Theme.paddingLg * 2, screen.height - margins.top - 16)
  color: "transparent"

  WlrLayershell.namespace: "quickshell:controlcenter"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0
  visible: false

  Shortcut {
    sequence: "Escape"
    onActivated: root.closeRequested()
  }

  // Volume and the active network are reactive bindings now. Brightness still
  // needs a (device agnostic) brightnessctl read; bluetooth/gammastep only have
  // shell APIs, so they poll on a much slower cadence than before.
  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: if (!brightProc.running) brightProc.running = true
  }

  Timer {
    interval: 3000
    running: root.visible
    repeat: true
    onTriggered: refreshSlow()
  }

  Component.onCompleted: refreshInfo()

  onVisibleChanged: if (visible) refreshInfo()

  function refreshInfo() {
    if (!brightProc.running) brightProc.running = true
    refreshSlow()
  }

  function refreshSlow() {
    if (!btProc.running) btProc.running = true
    if (!gsCheckProc.running) gsCheckProc.running = true
  }

  function restart(proc, argv) {
    proc.command = argv
    proc.running = false
    proc.running = true
  }

  function splitNmcli(line) {
    const out = []
    let cur = ""
    for (let i = 0; i < line.length; i++) {
      const c = line[i]
      if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
      if (c === ":") { out.push(cur); cur = ""; continue }
      cur += c
    }
    out.push(cur)
    return out
  }

  // --- Processes ---
  Process {
    id: brightProc
    command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%k'"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const b = parseInt(data)
        if (!isNaN(b)) {
          brightValue.set(b)
        }
      }
    }
  }

  QtObject {
    id: brightValue
    property int value: 50
    function set(v) { value = v }
  }

  Process {
    id: brightSetProc
    running: false
  }

  Process {
    id: volSetProc
    running: false
  }

  Process {
    id: netListProc
    command: ["bash", "-c", "nmcli -t -f NAME,SIGNAL,SECURITY device wifi list 2>/dev/null | head -40"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const parts = root.splitNmcli(data)
        if (parts.length === 0 || !parts[0]) return
        root.pendingNetworks.push({
          name: parts[0],
          signal: parts.length > 1 ? (parseInt(parts[1]) || 0) : 0,
          secured: parts.length > 2 && parts[2].trim() !== ""
        })
      }
    }
    onExited: {
      root.networks = root.pendingNetworks.slice()
      root.pendingNetworks = []
    }
  }

  Process {
    id: netConnectProc
    running: false
    onExited: {
      root.showNetworks = false
      root.pendingNetworks = []
    }
  }

  Process {
    id: wifiToggleProc
    running: false
  }

  Process {
    id: btProc
    command: ["bash", "-c", "bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const v = data.trim()
        if (v === "yes" || v === "no") root.bluetoothEnabled = v === "yes"
      }
    }
  }

  Process {
    id: btToggleProc
    running: false
  }

  Process {
    id: gsCheckProc
    command: ["pgrep", "gammastep"]
    running: false
    onExited: exitCode => {
      root.nightLight = exitCode === 0
    }
  }

  Process {
    id: gsToggleProc
    running: false
    onExited: gsCheckProc.running = true
  }

  Process {
    id: darkSetProc
    running: false
  }

  function setVolume(v) {
    restart(volSetProc, ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(Math.max(0, Math.min(150, v)) / 100)])
  }

  function setBrightness(v) {
    restart(brightSetProc, ["brightnessctl", "set", Math.max(0, Math.min(100, v)) + "%"])
    brightnessReadTimer.restart()
  }

  function setWifi(enabled) {
    restart(wifiToggleProc, ["nmcli", "radio", "wifi", enabled ? "on" : "off"])
  }

  function setBluetooth(enabled) {
    restart(btToggleProc, ["bluetoothctl", "power", enabled ? "on" : "off"])
    btTimer.restart()
  }

  function setNightLight(enabled) {
    restart(gsToggleProc, enabled
      ? ["gammastep", "-m", "wayland", "-O", "16000"]
      : ["killall", "gammastep"])
  }

  function setDarkMode(enabled) {
    Theme.darkMode = enabled
    restart(darkSetProc, ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
                          enabled ? "prefer-dark" : "prefer-light"])
  }

  function connectNetwork(name) {
    restart(netConnectProc, ["nmcli", "device", "wifi", "connect", name])
  }

  function toggleNetworkList() {
    showNetworks = !showNetworks
    if (showNetworks) {
      networks = []
      pendingNetworks = []
      restart(netListProc, ["bash", "-c", "nmcli -t -f NAME,SIGNAL,SECURITY device wifi list 2>/dev/null | head -40"])
    }
  }

  Timer {
    id: brightnessReadTimer
    interval: 250
    onTriggered: if (!brightProc.running) brightProc.running = true
  }

  Timer {
    id: btTimer
    interval: 600
    onTriggered: btProc.running = true
  }

  // --- UI ---
  Rectangle {
    anchors.fill: parent
    color: Theme.base
    radius: Theme.radiusLg

    Flickable {
      id: flick
      anchors.fill: parent
      contentWidth: width
      contentHeight: col.implicitHeight + Theme.paddingLg * 2
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: col
        x: Theme.paddingLg
        y: Theme.paddingLg
        width: flick.width - Theme.paddingLg * 2
        spacing: Theme.spacingLg

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing

        Text {
          text: ""
          color: Theme.lavender
          font { family: Theme.nerdFont; pixelSize: 16; weight: Theme.fontWeight }
        }

        Text {
          text: "Control Center"
          color: Theme.text
          font { family: Theme.font; pixelSize: 14; weight: 800 }
        }

        Item { Layout.fillWidth: true }

        Pill {
          icon: Theme.darkMode ? String.fromCodePoint(0xF0594) : String.fromCodePoint(0xF0599)
          label: Theme.darkMode ? "Dark" : "Light"
          checked: Theme.darkMode
          checkedColor: Theme.mauve
          onToggled: root.setDarkMode(checked)
        }
      }

      // Sliders
      Card {
        Layout.fillWidth: true
        icon: ""
        iconColor: Theme.yellow
        title: "Volume"

        Slider {
          Layout.fillWidth: true
          value: root.volume
          barColor: Theme.yellow
          onChanged: v => root.setVolume(v)
        }
      }

      Card {
        Layout.fillWidth: true
        icon: root.brightness === 0 ? String.fromCodePoint(0xF00DA)
            : root.brightness < 34 ? String.fromCodePoint(0xF00DC)
            : root.brightness < 67 ? String.fromCodePoint(0xF00DE)
            : String.fromCodePoint(0xF00E0)
        iconColor: Theme.peach
        title: "Brightness"

        Slider {
          Layout.fillWidth: true
          value: root.brightness
          barColor: Theme.peach
          onChanged: v => root.setBrightness(v)
        }
      }

      // Battery Card (UPower)
      Card {
        Layout.fillWidth: true
        visible: root.hasBattery
        icon: {
          if (root.charging) return String.fromCodePoint(0xF0084)
          if (root.batteryLevel >= 100) return String.fromCodePoint(0xF0079)
          if (root.batteryLevel < 10) return String.fromCodePoint(0xF0083)
          return String.fromCodePoint(0xF007A + (Math.floor(root.batteryLevel / 10) - 1))
        }
        iconColor: root.charging ? Theme.green
                 : root.batteryLevel <= 15 ? Theme.red
                 : root.batteryLevel <= 30 ? Theme.peach
                 : Theme.green
        title: "Battery"

        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.spacing

          Text {
            text: root.batteryLevel + "%"
            color: Theme.text
            font { family: Theme.font; pixelSize: 18; weight: 800 }
          }

          Item { Layout.fillWidth: true }

          ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight

            Text {
              text: root.batteryState
              color: Theme.subtext0
              font { family: Theme.font; pixelSize: 10; weight: 700 }
            }

            Text {
              text: root.batteryTime
              visible: text !== ""
              color: Theme.overlay0
              font { family: Theme.font; pixelSize: 10; weight: 600 }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 6
          radius: 3
          color: Theme.surface1

          Rectangle {
            width: parent.width * root.batteryLevel / 100
            height: parent.height
            radius: 3
            color: root.charging ? Theme.green
                 : root.batteryLevel <= 15 ? Theme.red
                 : root.batteryLevel <= 30 ? Theme.peach
                 : Theme.green

            Behavior on width { NumberAnimation { duration: 250 } }
          }
        }
      }

      // Quick Toggles
      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing

        Pill {
          Layout.fillWidth: true
          icon: ""
          label: "Wi-Fi"
          checked: root.wifiEnabled
          checkedColor: Theme.green
          onToggled: root.setWifi(checked)
        }

        Pill {
          Layout.fillWidth: true
          icon: root.bluetoothEnabled ? String.fromCodePoint(0xF00AF) : String.fromCodePoint(0xF00B2)
          label: "Bluetooth"
          checked: root.bluetoothEnabled
          checkedColor: Theme.blue
          onToggled: root.setBluetooth(checked)
        }
      }

      // Network Card with Dropdown
      Card {
        Layout.fillWidth: true
        icon: ""
        iconColor: Theme.pink
        title: "Network"

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Theme.spacingSm

          // Current connection
          Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Theme.radiusSm
            color: Theme.surface1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Theme.paddingSm
              spacing: Theme.spacingSm

              Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: root.networkConnected ? Theme.green : Theme.red
              }

              Text {
                text: root.networkConnected ? root.networkName : "Disconnected"
                color: root.networkConnected ? Theme.text : Theme.overlay0
                font { family: Theme.font; pixelSize: 12; weight: 600 }
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              // Dropdown toggle
              Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: netToggleArea.containsMouse ? Theme.surface2 : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: ""
                  color: Theme.overlay0
                  font { family: Theme.nerdFont; pixelSize: 10; weight: Theme.fontWeight }
                  rotation: root.showNetworks ? 180 : 0

                  Behavior on rotation { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                  id: netToggleArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleNetworkList()
                }
              }
            }
          }

          // Network list dropdown
          Rectangle {
            Layout.fillWidth: true
            height: root.showNetworks ? Math.min(root.networks.length * 36 + 8, 180) : 0
            radius: Theme.radiusSm
            color: Theme.surface0
            clip: true
            visible: root.showNetworks

            Behavior on height { NumberAnimation { duration: 200 } }

            Text {
              anchors.centerIn: parent
              visible: root.networks.length === 0
              text: "Scanning..."
              color: Theme.overlay0
              font { family: Theme.font; pixelSize: 11; weight: 600 }
            }

            ListView {
              anchors.fill: parent
              anchors.margins: 4
              clip: true
              model: root.networks

              delegate: Rectangle {
                required property var modelData
                required property int index
                height: 32
                radius: 4
                color: netItemArea.containsMouse ? Theme.surface1 : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: Theme.spacingSm

                  Text {
                    text: modelData.signal >= 75 ? ""
                        : modelData.signal >= 40 ? ""
                        : ""
                    color: modelData.signal >= 75 ? Theme.green
                         : modelData.signal >= 40 ? Theme.yellow
                         : Theme.red
                    font { family: Theme.nerdFont; pixelSize: 12; weight: Theme.fontWeight }
                  }

                  Text {
                    text: modelData.name
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 11; weight: 600 }
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }

                  Text {
                    text: ""
                    color: Theme.overlay0
                    font { family: Theme.nerdFont; pixelSize: 10; weight: Theme.fontWeight }
                    visible: modelData.secured
                  }

                  Text {
                    text: modelData.signal + "%"
                    color: Theme.overlay0
                    font { family: Theme.font; pixelSize: 10; weight: 600 }
                  }
                }

                MouseArea {
                  id: netItemArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.connectNetwork(modelData.name)
                }
              }
            }
          }
        }
      }

      // Power Profile Card
      Card {
        Layout.fillWidth: true
        icon: String.fromCodePoint(0xF04C5)
        iconColor: Theme.sapphire
        title: "Power Profile"

        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.spacingSm

          Pill {
            label: "Saver"
            checked: PowerProfiles.profile === PowerProfile.PowerSaver
            checkedColor: Theme.green
            onToggled: PowerProfiles.profile = PowerProfile.PowerSaver
          }

          Pill {
            label: "Balanced"
            checked: PowerProfiles.profile === PowerProfile.Balanced
            checkedColor: Theme.blue
            onToggled: PowerProfiles.profile = PowerProfile.Balanced
          }

          Pill {
            visible: PowerProfiles.hasPerformanceProfile
            label: "Performance"
            checked: PowerProfiles.profile === PowerProfile.Performance
            checkedColor: Theme.peach
            onToggled: PowerProfiles.profile = PowerProfile.Performance
          }

          Item { Layout.fillWidth: true }
        }
      }

      // Night Light Card
      Card {
        Layout.fillWidth: true
        icon: String.fromCodePoint(0xF0594)
        iconColor: root.nightLight ? Theme.peach : Theme.overlay0
        title: "Night Light"

        RowLayout {
          Layout.fillWidth: true
          spacing: Theme.spacing

          Text {
            text: root.nightLight ? "Active" : "Inactive"
            color: root.nightLight ? Theme.peach : Theme.overlay0
            font { family: Theme.font; pixelSize: 11; weight: 700 }
          }

          Item { Layout.fillWidth: true }

          Pill {
            label: root.nightLight ? "On" : "Off"
            checked: root.nightLight
            checkedColor: Theme.peach
            onToggled: root.setNightLight(checked)
          }
        }
      }

      // Notifications Card
      Card {
        id: notifCard
        Layout.fillWidth: true
        icon: ""
        iconColor: Theme.mauve
        title: "Notifications"

        property var history: []
        property int maxHistory: 20
        readonly property bool hasHistory: history != null && history.length > 0

        Connections {
          target: NotificationBridge
          function onNotified(key, appName, summary, body, urgency, isTransient) {
            if (isTransient) return
            const entry = {
              key: key,
              appName: appName,
              summary: summary,
              body: body,
              urgency: urgency,
              receivedAt: new Date()
            }
            const prev = Array.isArray(notifCard.history) ? notifCard.history : []
            notifCard.history = [entry, ...prev].slice(0, notifCard.maxHistory)
          }
        }

        RowLayout {
          Layout.fillWidth: true
          visible: notifCard.hasHistory
          spacing: Theme.spacing

          Text {
            text: notifCard.history.length + " earlier"
            color: Theme.overlay0
            font { family: Theme.font; pixelSize: 10; weight: 600 }
          }

          Item { Layout.fillWidth: true }

          Text {
            text: "Clear"
            color: clearArea.containsMouse ? Theme.red : Theme.overlay0
            font { family: Theme.font; pixelSize: 10; weight: 700 }

            MouseArea {
              id: clearArea
              anchors.fill: parent
              anchors.margins: -6
              hoverEnabled: true
              onClicked: notifCard.history = []
            }
          }
        }

        ListView {
          Layout.fillWidth: true
          Layout.preferredHeight: notifCard.hasHistory ? Math.min(notifCard.history.length * 40, 160) : 0
          clip: true

          model: ScriptModel {
            values: notifCard.history
            objectProp: "key"
          }

          delegate: Rectangle {
            required property var modelData
            height: 36
            radius: Theme.radiusSm
            color: Theme.surface1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Theme.paddingSm
              spacing: Theme.spacingSm

              Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: modelData.urgency === NotificationUrgency.Critical ? Theme.red : Theme.blue
              }

              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Text {
                  text: modelData.summary
                  textFormat: Text.PlainText
                  color: Theme.text
                  font { family: Theme.font; pixelSize: 11; weight: 700 }
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: modelData.body !== "" ? modelData.body : modelData.appName
                  textFormat: Text.PlainText
                  color: Theme.overlay0
                  font { family: Theme.font; pixelSize: 9; weight: 600 }
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== ""
                }
              }

              Text {
                text: Qt.formatTime(modelData.receivedAt, "HH:mm")
                color: Theme.overlay0
                font { family: Theme.font; pixelSize: 9; weight: 600 }
              }
            }
          }
        }

        Text {
          text: "No notifications"
          color: Theme.subtext0
          font { family: Theme.font; pixelSize: 11; weight: 600 }
          visible: !notifCard.hasHistory
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Item { Layout.fillHeight: true }
      }
    }
  }
}
