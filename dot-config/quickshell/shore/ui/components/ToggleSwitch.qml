import QtQuick
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

// Deliberate on/off switch (a click toggles it, but it lives inside a menu
// rather than on a bar right-click, so it is hard to hit by accident).
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 24
    radius: 12
    color: checked ? Theme.tint(Theme.green, 0.85) : Theme.tint(Theme.surface1, 0.6)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.7)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Rectangle {
        id: knob
        width: 20
        height: 20
        radius: 10
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: Theme.text

        Behavior on x {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
