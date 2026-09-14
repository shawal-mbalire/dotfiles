import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "domain"
import "infra"
import "adapters"
import "ports"
import "ui"
import "ui/components"
import "ui/panels"

// Composition root. Wires the driven adapters into the UI (driving adapters):
//   wallpaper + bar (per monitor) + control center + notification daemon + OSD
//   + launcher + screenshot + session lock.
// The only place that knows every layer; it verifies each adapter against its
// port contract before the shell is trusted.
ShellRoot {
    id: root

    Component.onCompleted: {
        Verify.assertPorts([
            { adapter: Audio, methods: Verify.audioPort, name: "AudioPort" },
            { adapter: Auth, methods: Verify.authPort, name: "AuthPort" },
            { adapter: Backlight, methods: Verify.brightnessPort, name: "BrightnessPort" },
            { adapter: Battery, methods: Verify.batteryPort, name: "BatteryPort" },
            { adapter: Bluetooth, methods: Verify.bluetoothPort, name: "BluetoothPort" },
            { adapter: Compositor, methods: Verify.compositorPort, name: "CompositorPort" },
            { adapter: Clipboard, methods: Verify.clipboardPort, name: "ClipboardPort" },
            { adapter: Launcher, methods: Verify.launcherPort, name: "LauncherPort" },
            { adapter: Media, methods: Verify.mediaPort, name: "MediaPort" },
            { adapter: Network, methods: Verify.networkPort, name: "NetworkPort" },
            { adapter: Nightlight, methods: Verify.nightlightPort, name: "NightlightPort" },
            { adapter: Notifications, methods: Verify.notificationsPort, name: "NotificationPort" },
            { adapter: Polkit, methods: Verify.polkitPort, name: "PolkitPort" },
            { adapter: Screenshots, methods: Verify.screenshotsPort, name: "ScreenshotsPort" },
            { adapter: Session, methods: Verify.sessionPort, name: "SessionPort" },
            { adapter: Tray, methods: Verify.trayPort, name: "TrayPort" },
            { adapter: Wallpaper, methods: Verify.wallpaperPort, name: "WallpaperPort" }
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
    PolkitPrompt {}
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
