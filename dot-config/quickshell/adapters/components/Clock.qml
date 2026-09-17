import QtQuick
import Quickshell
import ".."
import "../../domain"
import "../../adapters"

Pill {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: true
    }

    // waybar `format-alt`: click toggles between time and date.
    property bool showDate: false

    icon: Theme.iconClock
    iconColor: Theme.peach
    text: showDate
        ? Qt.formatDateTime(clock.date, "ddd d MMM")
        : Qt.formatDateTime(clock.date, "HH:mm")
    textColor: Theme.text

    onClicked: showDate = !showDate
}
