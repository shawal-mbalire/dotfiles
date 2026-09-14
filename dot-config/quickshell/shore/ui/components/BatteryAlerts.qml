import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Driving watcher: turns UPower changes into battery threshold notifications.
// Emits at most once per threshold per charge state (re-armed on state change).
Item {
    id: root

    readonly property var battery: UPower.displayDevice

    property var claimed: ({})
    property string lastState: ""

    Connections {
        target: root.battery
        function onPercentageChanged() {
            root.check();
        }
        function onStateChanged() {
            root.check();
        }
    }

    Component.onCompleted: check()

    function isCharging(b) {
        return b.state === UPowerDeviceState.Charging
            || b.state === UPowerDeviceState.FullyCharged
            || b.state === UPowerDeviceState.PendingCharge;
    }

    function check() {
        const b = root.battery;
        if (!b || !b.isPresent || !b.ready) return;

        const state = String(b.state);
        if (state !== root.lastState) {
            root.claimed = ({});
            root.lastState = state;
        }

        const alert = Formatters.batteryAlert(Formatters.percent(b.percentage), isCharging(b));
        if (!alert || root.claimed[alert.marker]) return;

        const claimed = root.claimed;
        claimed[alert.marker] = true;
        root.claimed = claimed;
        Notifications.notify(alert.summary, alert.body, alert.urgency);
    }
}
