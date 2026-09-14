import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "domain"
import "infra"
import "adapters"
import "ports"
import "ui"
import "ui/components"
import "ui/panels"

// Composition root. Wires the driven adapters into the UI (driving adapters):
//   bar (per monitor) + control center + notification daemon + OSD.
// The only place that knows every layer; it verifies each adapter against its
// port contract before the shell is trusted.
ShellRoot {
    id: root

    Component.onCompleted: {
        Verify.assertPorts([
            { adapter: Backlight, methods: Verify.brightnessPort, name: "BrightnessPort" },
            { adapter: Nightlight, methods: Verify.nightlightPort, name: "NightlightPort" },
            { adapter: Network, methods: Verify.networkPort, name: "NetworkPort" },
            { adapter: Notifications, methods: Verify.notificationsPort, name: "NotificationPort" },
            { adapter: Polkit, methods: Verify.polkitPort, name: "PolkitPort" }
        ]);
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    ControlCenter {}
    MenuPopup {}
    NotificationPopups {}
    Osd {}
    PolkitPrompt {}

    // Turns UPower changes into battery threshold notifications.
    BatteryAlerts {}

    // Track the default sink so volume changes can raise the OSD.
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            root.showAudioOsd();
        }
        function onMutedChanged() {
            root.showAudioOsd();
        }
    }

    function showAudioOsd() {
        const sink = Pipewire.defaultAudioSink;
        if (!sink || !sink.audio) return;
        UiState.showOsd(
            sink.audio.muted ? Theme.iconVolumeMuted : Theme.iconVolume,
            sink.audio.volume,
            sink.audio.muted ? "muted" : Formatters.percent(sink.audio.volume) + "%"
        );
    }

    // Called by Hyprland keybinds: `qs -c shore ipc call quickshell <function>`.
    IpcHandler {
        target: "quickshell"

        function toggleControlCenter() {
            UiState.toggleControlCenter();
        }

        function toggleBar() {
            UiState.toggleBar();
        }

        function closePanels() {
            UiState.closePanels();
        }

        function openMenu(name: string) {
            UiState.toggleMenu(name);
        }

        function toggleDnd() {
            Notifications.toggleDnd();
        }

        function clearNotifications() {
            Notifications.dismissAll();
        }

        function brightnessStep(direction: string) {
            const delta = direction === "up" ? Constants.brightnessStep : -Constants.brightnessStep;
            Backlight.step(delta);
            UiState.showOsd(
                Theme.iconBrightness,
                (Backlight.percent + delta) / 100,
                (Backlight.percent + delta) + "%"
            );
        }
    }
}
