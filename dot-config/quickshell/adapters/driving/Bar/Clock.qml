// Quickshell reference: https://quickshell.org/docs/v0.3.0/types/Quickshell/
import "../../../infra/config"
import "../Shared"
import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    text: Qt.formatDateTime(clock.date, "MMM d")
    color: Theme.overlay0
    font {
      family: Theme.font
      pixelSize: Theme.fontSize
      weight: Theme.fontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }

  Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
    color: Theme.text
    font {
      family: Theme.font
      pixelSize: Theme.fontSize
      weight: Theme.fontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }
}
