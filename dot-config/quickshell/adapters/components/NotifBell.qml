import QtQuick
import ".."
import "../../domain"
import "../../adapters"

Pill {
    id: root

    icon: Notifications.dnd ? Theme.iconBellDnd : Theme.iconBell
    iconColor: Notifications.count > 0 ? WallpaperColors.accent
             : Notifications.dnd ? Theme.overlay0
             : Theme.subtext1
    text: Notifications.count > 0 ? String(Notifications.count) : ""

    // left: panel, right: DND, middle: clear (waybar parity)
    onClicked: UiState.toggleMenu("system")
    onSecondaryClicked: Notifications.toggleDnd()
    onMiddleClicked: Notifications.dismissAll()
}
