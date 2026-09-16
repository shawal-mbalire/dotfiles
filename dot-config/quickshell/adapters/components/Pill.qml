import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// The shared bar chip: rounded, translucent, optionally icon + text.
Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property color iconColor: Theme.subtext1
    property color textColor: Theme.subtext1
    property color accent: Theme.surface0
    property bool highlighted: false

    signal clicked()
    signal secondaryClicked()
    signal middleClicked()
    signal wheel(int delta)

    implicitWidth: layout.implicitWidth + Theme.padH * 2
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: highlighted ? Theme.tint(accent, 0.85) : Theme.tint(Theme.surface0, 0.85)
    border.width: 1
    border.color: Theme.tint(Theme.surface1, 0.85)

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.fontSize
            color: root.iconColor
        }

        Text {
            visible: root.text !== ""
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.textColor
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.secondaryClicked();
            else if (mouse.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
        onWheel: wheel => root.wheel(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
