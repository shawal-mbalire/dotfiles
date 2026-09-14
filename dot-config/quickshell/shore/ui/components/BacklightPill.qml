import QtQuick
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    icon: Theme.iconBrightness
    iconColor: Theme.yellow
    text: Backlight.percent + "%"

    // left: control center slider, right: also control center (no fuzzel menus)
    onClicked: UiState.toggleControlCenter()
    onSecondaryClicked: UiState.toggleControlCenter()

    onWheel: delta => {
        Backlight.step(delta * 5);
        UiState.showOsd(Theme.iconBrightness,
            (Backlight.percent + delta * 5) / 100,
            (Backlight.percent + delta * 5) + "%");
    }
}
