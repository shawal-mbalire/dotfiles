import QtQuick
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// Small labelled action button used inside bar submenus.
Rectangle {
    id: root

    property string label: ""
    signal clicked()

    implicitWidth: labelText.implicitWidth + 18
    implicitHeight: 24
    radius: Theme.radius - 3
    color: hover.pressed ? Theme.tint(Theme.surface1, 0.6)
         : hover.containsMouse ? Theme.tint(Theme.surface1, 0.85)
         : Theme.tint(Theme.surface1, 0.5)
    border.width: 1
    border.color: hover.containsMouse ? Theme.tint(Theme.surface1, 0.85)
                      : Theme.tint(Theme.surface1, 0.6)

    Behavior on color { ColorAnimation { duration: 80 } }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.text
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
