// Wallpaper drawn by Quickshell itself: one background layer surface per screen,
// showing the port's current image. Sits below every window and takes no input.
// Its namespace is "quickshell-wallpaper" (not "quickshell:…") so the Hyprland
// blur rule for the shell's panels leaves it sharp.
import "../../../domain/ports"
import "../../../domain/constants"
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  // Set by the owning Variants delegate to this window's screen.
  property var modelData
  required property WallpaperPort wallpaperPort
  screen: modelData

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "black"
  exclusiveZone: -1
  WlrLayershell.namespace: "quickshell-wallpaper"
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Image {
    anchors.fill: parent
    source: WallpaperPolicy.toFileUrl(root.wallpaperPort.current)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize: Qt.size(root.width, root.height)
    onStatusChanged: if (status === Image.Error) console.warn("[Wallpaper] failed to load", source)
  }
}
