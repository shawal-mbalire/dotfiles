import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../domain"
import "../../infra"

// Renders the wallpaper on the background layer of every monitor.
// Replaces hyprpaper.
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
            source: Config.wallpaper !== "" ? "file://" + Config.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
