import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "domain"
import "infra"
import "adapters"
import "adapters/components"
import "adapters/panels"

// Composition root. Wires the driven adapters into the UI (driving adapters):
//   wallpaper + bar (per monitor) + control center + notification daemon + OSD
//   + launcher + screenshot + session lock.
// The only place that knows every layer; it verifies each adapter against its
// port contract before the shell is trusted.
ShellRoot {
    id: root

    Component.onCompleted: {
        Verify.assertPorts([
            { adapter: Audio, methods: Ports.audioPort, name: "AudioPort" },
            { adapter: Auth, methods: Ports.authPort, name: "AuthPort" },
            { adapter: Backlight, methods: Ports.brightnessPort, name: "BrightnessPort" },
            { adapter: Battery, methods: Ports.batteryPort, name: "BatteryPort" },
            { adapter: Bluetooth, methods: Ports.bluetoothPort, name: "BluetoothPort" },
            { adapter: Compositor, methods: Ports.compositorPort, name: "CompositorPort" },
            { adapter: Clipboard, methods: Ports.clipboardPort, name: "ClipboardPort" },
            { adapter: Launcher, methods: Ports.launcherPort, name: "LauncherPort" },
            { adapter: Media, methods: Ports.mediaPort, name: "MediaPort" },
            { adapter: Network, methods: Ports.networkPort, name: "NetworkPort" },
            { adapter: Nightlight, methods: Ports.nightlightPort, name: "NightlightPort" },
            { adapter: Notifications, methods: Ports.notificationsPort, name: "NotificationPort" },

            { adapter: Screenshots, methods: Ports.screenshotsPort, name: "ScreenshotsPort" },
            { adapter: Session, methods: Ports.sessionPort, name: "SessionPort" },
            { adapter: Tray, methods: Ports.trayPort, name: "TrayPort" },
            { adapter: Wallpaper, methods: Ports.wallpaperPort, name: "WallpaperPort" }
        ]);
        Idle.enabled = !UiState.locked;
    }

    // ── Wallpaper ─────────────────────────────────────────────────────────
    WallpaperSurface {}

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // ── Overlays / panels ─────────────────────────────────────────────────
    ControlCenter {}
    MenuPopup {}
    NotificationPopups {}
    Osd {}

    Launcher {}
    ScreenshotOverlay {}

    // Turns UPower changes into battery threshold notifications.
    BatteryAlerts {}

    // Raises the volume OSD on default-sink changes.
    VolumeOsd {}

    // ── Session lock ──────────────────────────────────────────────────────
    Connections {
        target: Auth
        function onUnlocked() {
            UiState.locked = false;
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: UiState.locked

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: Auth
            }
        }
    }

    // ── Idle (replaces hypridle) ──────────────────────────────────────────
    Connections {
        target: Idle
        function onLockRequested() {
            UiState.lock();
        }
        function onSuspendRequested() {
            Session.suspend();
        }
    }

    Connections {
        target: UiState
        function onLockedChanged() {
            Idle.enabled = !UiState.locked;
        }
    }

    // Called by Hyprland keybinds: `qs -c shore ipc call quickshell <function>`.
    // Every operation is measured against Constants.timeBudgetMs.
    IpcHandler {
        target: "quickshell"

        function toggleControlCenter() {
            Measure.run("toggleControlCenter", () => UiState.toggleControlCenter());
        }

        function toggleBar() {
            Measure.run("toggleBar", () => UiState.toggleBar());
        }

        function closePanels() {
            Measure.run("closePanels", () => UiState.closePanels());
        }

        function openMenu(name: string) {
            Measure.run("openMenu:" + name, () => UiState.toggleMenu(name));
        }

        function toggleDnd() {
            Measure.run("toggleDnd", () => Notifications.toggleDnd());
        }

        function clearNotifications() {
            Measure.run("clearNotifications", () => Notifications.dismissAll());
        }

        function brightnessStep(direction: string) {
            Measure.run("brightnessStep:" + direction, () => {
                const delta = direction === "up" ? Constants.brightnessStep : -Constants.brightnessStep;
                Backlight.step(delta);
                UiState.showOsd(
                    Theme.iconBrightness,
                    (Backlight.percent + delta) / 100,
                    (Backlight.percent + delta) + "%"
                );
            });
        }

        function lock() {
            Measure.run("lock", () => UiState.lock());
        }

        // TEMP: escape a stuck lock screen
        function forceUnlock() {
            Measure.run("forceUnlock", () => Auth.forceUnlock());
        }

        function openLauncher(mode: string) {
            Measure.run("openLauncher:" + mode, () => {
                if (mode === "clipboard") Clipboard.refresh();
                UiState.toggleLauncher(mode);
            });
        }

        function screenshot() {
            Measure.run("screenshot", () => UiState.toggleScreenshot());
        }

        function nextWallpaper() {
            Measure.run("nextWallpaper", () => Wallpaper.next());
        }
    }
}
