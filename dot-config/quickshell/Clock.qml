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
    color: colorOverlay0
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }

  Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
    color: colorText
    font {
      family: themeFont
      pixelSize: themeFontSize
      weight: themeFontWeight
    }
    Layout.alignment: Qt.AlignVCenter
  }
}
