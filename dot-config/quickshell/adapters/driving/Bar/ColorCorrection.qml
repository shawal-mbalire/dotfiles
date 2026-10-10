import "../../../infra/config"
import "../Shared"
import "../../../domain/ports"
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  required property ColorCorrectionPort colorCorrectionPort

  readonly property bool active: colorCorrectionPort.active

  Text {
    text: String.fromCodePoint(0xF0594)
    color: root.active ? Theme.peach : Theme.overlay0
    font { family: Theme.nerdFont; pixelSize: Theme.fontSize; weight: Theme.fontWeight }
  }

  TapHandler {
    cursorShape: Qt.PointingHandCursor
    onTapped: root.colorCorrectionPort.setActive(!root.active)
  }
}
