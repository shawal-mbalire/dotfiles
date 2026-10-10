import "../../../infra/config"
import QtQuick
import "."

// Circular transport button. The glyph is a Nerd Font codepoint chosen by the
// caller; `primary` enlarges the play/pause button relative to the skips.
Rectangle {
  id: root

  property string icon: ""
  property bool primary: false
  signal clicked()

  implicitWidth: primary ? 38 : 30
  implicitHeight: primary ? 38 : 30
  radius: height / 2
  color: area.pressed ? Theme.surface2
       : area.containsMouse && root.enabled ? Theme.surface1
       : "transparent"
  opacity: root.enabled ? 1 : 0.35

  Behavior on color { ColorAnimation { duration: Theme.animFast } }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.primary ? Theme.mauve : Theme.text
    font {
      family: Theme.nerdFont
      pixelSize: root.primary ? 18 : 14
      weight: Theme.fontWeight
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
