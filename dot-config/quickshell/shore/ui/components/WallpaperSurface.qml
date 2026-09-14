import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../domain"
import "../../infra"
import "../../adapters"

// Renders the current wallpaper on the background layer of every monitor.
// Replaces hyprpaper; `Wallpaper.next()` cycles the set in Config.wallpaperDir.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "black"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-wallpaper"

        Image {
            anchors.fill: parent
            source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
