import QtQuick
import "../../domain"

// Horizontal slider with a draggable grab handle. `value` is 0..1 and stays
// the caller's binding; `moved` fires only while the user interacts, so the
// owner decides what to persist. Reused by every horizontal bar (audio,
// backlight, ...) so they all share one feel and one implementation.
Item {
    id: root

    property real value: 0
    property bool enabled: true
    property color accent: "#89b4fa"
    property color trackColor: Qt.rgba(1, 1, 1, 0.15)
    property color handleColor: accent
    property real _lastEmit: 0

    signal moved(real value)

    implicitHeight: 20
    implicitWidth: 120

    function clamp01(v) {
        return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0;
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: Theme.radius
        color: root.trackColor

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.clamp01(root.value)
            radius: parent.radius
            color: root.enabled ? root.accent : Qt.rgba(1, 1, 1, 0.2)
        }
    }

    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: width / 2
        color: root.handleColor
        border.width: 2
        border.color: Qt.rgba(0, 0, 0, 0.35)
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width,
            root.clamp01(root.value) * root.width - width / 2))
        scale: area.pressed ? 1.2 : (area.containsMouse && root.enabled ? 1.08 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 90 }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function emit(x) {
            root.moved(root.clamp01(x / root.width));
        }

        onPressed: mouse => emit(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) {
                const now = Date.now();
                if (now - root._lastEmit > 16) {
                    root._lastEmit = now;
                    emit(mouse.x);
                }
            }
        }
    }
}
