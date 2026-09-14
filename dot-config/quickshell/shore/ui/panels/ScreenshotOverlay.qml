import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../../domain"
import "../../adapters"
import "../../infra"

// Region screenshot overlay. Captures the screen, lets the user drag a
// rectangle, then saves it and copies it to the clipboard. Replaces grimblast.
LazyLoader {
    id: loader
    active: UiState.screenshotOpen

    PanelWindow {
        id: overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        property real sx: 0
        property real sy: 0
        property real ex: 0
        property real ey: 0
        property bool selecting: false

        function grab() {
            const x = Math.min(overlay.sx, overlay.ex);
            const y = Math.min(overlay.sy, overlay.ey);
            const w = Math.abs(overlay.ex - overlay.sx);
            const h = Math.abs(overlay.ey - overlay.sy);
            if (w < 5 || h < 5) {
                UiState.closeScreenshot();
                return;
            }
            region.sourceRect = Qt.rect(x, y, w, h);
            region.width = w;
            region.height = h;
            region.grabToImage(result => {
                const dir = Config.home + "/" + Constants.screenshotDir;
                const path = dir + "/shot-" + Date.now() + ".png";
                result.saveToFile(path);
                Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")"; wl-copy < "$1"', "sh", path]);
                UiState.closeScreenshot();
            });
        }



        ScreencopyView {
            id: capture
            anchors.fill: parent
            captureSource: overlay.screen
            paintCursor: false
            live: true
        }

        // Cropped snapshot used to produce the file. Kept behind the capture so
        // it stays renderable (grabToImage needs a rendered item).
        ShaderEffectSource {
            id: region
            z: -1
            width: 0
            height: 0
            sourceItem: capture
            live: true
            hideSource: false
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.28)
        }

        Rectangle {
            visible: overlay.selecting
            x: Math.min(overlay.sx, overlay.ex)
            y: Math.min(overlay.sy, overlay.ey)
            width: Math.abs(overlay.ex - overlay.sx)
            height: Math.abs(overlay.ey - overlay.sy)
            color: "transparent"
            border.width: 2
            border.color: WallpaperColors.accent
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 40
            }
            text: "Drag to capture a region · Esc to cancel"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.text
        }

        MouseArea {
            anchors.fill: parent
            focus: true
            cursorShape: Qt.CrossCursor
            Keys.onEscapePressed: UiState.closeScreenshot()
            onPressed: mouse => {
                overlay.sx = mouse.x;
                overlay.sy = mouse.y;
                overlay.ex = mouse.x;
                overlay.ey = mouse.y;
                overlay.selecting = true;
            }
            onPositionChanged: mouse => {
                if (overlay.selecting) {
                    overlay.ex = mouse.x;
                    overlay.ey = mouse.y;
                }
            }
            onReleased: {
                overlay.selecting = false;
                overlay.grab();
            }
        }
    }
}
