import QtQuick
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

Pill {
    id: root

    icon: Theme.iconBrightness
    iconColor: Theme.yellow
    text: Backlight.percent + "%"

    // left: display menu, right: also display menu
    onClicked: UiState.toggleMenu("display")
    onSecondaryClicked: UiState.toggleMenu("display")

    onWheel: delta => {
        Backlight.step(delta * 5);
        UiState.showOsd(Theme.iconBrightness,
            (Backlight.percent + delta * 5) / 100,
            (Backlight.percent + delta * 5) + "%");
    }
}
