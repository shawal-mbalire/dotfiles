pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns the single Desktop Notifications daemon for the session.
// Replaces swaync + mako. Other surfaces read `model` / `dnd`.
Singleton {
    id: root

    // Do Not Disturb: new notifications are tracked but no popup is shown.
    property bool dnd: false

    // Most recent tracked notification, used by the popup surface.
    property var lastNotification: null
    property bool popupVisible: false

    readonly property var model: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    function toggleDnd() {
        dnd = !dnd;
    }

    function dismissAll() {
        const items = server.trackedNotifications.values;
        for (let i = items.length - 1; i >= 0; i--)
            items[i].dismiss();
    }

    function closePopup() {
        popupVisible = false;
    }

    // Send a notification through the session bus (lands in our own server).
    function notify(summary, body, urgency) {
        const args = ["notify-send", "-a", "shore"];
        if (urgency === "critical") args.push("-u", "critical");
        args.push(String(summary), String(body));
        Quickshell.execDetached(args);
    }

    NotificationServer {
        id: server

        actionsSupported: true
        inlineReplySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: n => {
            n.tracked = true;
            root.lastNotification = n;
            if (!root.dnd) {
                root.popupVisible = true;
                popupTimer.restart();
            }
        }
    }

    Timer {
        id: popupTimer
        interval: 6000
        onTriggered: root.popupVisible = false
    }
}
