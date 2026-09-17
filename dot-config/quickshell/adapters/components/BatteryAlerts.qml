import QtQuick
import ".."
import "../../domain"
import "../../adapters"

// Driving watcher: turns battery changes into threshold notifications, at most
// once per threshold per charge state (re-armed on state change). Reads state
// through the Battery adapter; the alert rule itself is pure domain
// (Formatters.batteryAlert).
Item {
    id: root

    property var claimed: ({})
    property string lastState: ""

    Connections {
        target: Battery.device
        function onPercentageChanged() {
            root.check();
        }
        function onStateChanged() {
            root.check();
        }
    }

    Component.onCompleted: check()

    function check() {
        if (!Battery.present || !Battery.ready) return;

        const state = String(Battery.device.state);
        if (state !== root.lastState) {
            root.claimed = ({});
            root.lastState = state;
        }

        const alert = Formatters.batteryAlert(Battery.percent, Battery.charging);
        if (!alert || root.claimed[alert.marker]) return;

        const claimed = root.claimed;
        claimed[alert.marker] = true;
        root.claimed = claimed;
        Notifications.notify(alert.summary, alert.body, alert.urgency);
    }
}
