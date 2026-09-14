import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../domain"
import "../../infra"
import "../../adapters"

// Renders the current wallpaper on the background layer of every monitor.
// Replaces hyprpaper; `Wallpaper.next()` cycles the set in Config.wallpaperDir.
//
// Speed: the image is decoded at screen size (sourceSize) so a 4K JPEG is not
// decoded at full resolution, and the next wallpaper is preloaded into the
// pixmap cache so a forward toggle swaps instantly.
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
            id: bg
            anchors.fill: parent
            source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: modelData.width
            sourceSize.height: modelData.height
        }

        // Warm the cache for the next wallpaper so toggling is instant.
        Image {
            visible: false
            asynchronous: true
            cache: true
            sourceSize.width: bg.width
            sourceSize.height: bg.height
            source: {
                const images = Wallpaper.images;
                if (images.length < 2) return "";
                const next = (Wallpaper.index + 1) % images.length;
                return "file://" + images[next];
            }
        }
    }
}
