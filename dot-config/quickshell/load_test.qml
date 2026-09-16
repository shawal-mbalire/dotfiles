import QtQuick
import Quickshell
import "domain"
import "infra"
import "adapters"
import "adapters/components"
import "adapters/panels"

// Minimal shell for load-time testing.  Imports every module so the QML
// engine constructs all singletons; a shell script measures wall-clock time
// from process start to the [load-test] log line.
ShellRoot {
    id: root

    Component.onCompleted: {
        const probes = [
            Theme.base,
            Theme.text,
            Theme.radius,
            Theme.fontSize,
            Theme.fontFamily,
            Constants.brightnessStep,
            Constants.screenshotDir,
            Constants.timeBudgetMs,
            Formatters.percentToRaw(50, 0, 100),
            AudioGroups,
            Time.nowMs(),
            Measure.run("noop", () => {}),
            Ports,
            InfraConfig.home,
            InfraConfig.wallpaper,
            UiState.locked,
            Audio.nodes,
            Auth,
            Backlight,
            Battery,
            Bluetooth,
            Clipboard,
            Compositor,
            Idle,
            Launcher,
            Media,
            Network,
            Nightlight,
            Notifications,
            Screenshots,
            Session,
            Tray,
            Wallpaper,
            WallpaperColors
        ];

        console.log("[load-test] quickshell singletons OK (" + probes.length + " probes)");
    }
}
