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


  // date
  Text {
    text: Qt.formatDateTime(clock.date, "MMM d")
    color: "#5a4d3e"
    font {
      family: "Comfortaa"
      pixelSize: 15
      weight: 1000
    }
    Layout.alignment: Qt.AlignVCenter
  }

  // time
  Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
    color: "#f5e2c5"
    font {
      family: "Comfortaa"
      pixelSize: 15
      weight: 1000
    }
    Layout.alignment: Qt.AlignVCenter
  }
}

