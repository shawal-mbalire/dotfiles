import QtQuick
import QtQuick.Layouts
import "../../domain"

// Small uppercase section header that establishes hierarchy inside a menu.
Text {
    id: root

    property string label: ""

    Layout.fillWidth: true
    text: root.label.toUpperCase()
    font.family: Theme.fontFamily
    font.pixelSize: 10
    font.letterSpacing: 1.2
    font.bold: true
    color: Theme.overlay0
}
