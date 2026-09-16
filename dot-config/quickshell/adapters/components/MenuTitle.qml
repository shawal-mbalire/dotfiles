import QtQuick
import QtQuick.Layouts
import "../../domain"

// Menu title block: bold title with an optional muted subtitle. Gives every
// menu a consistent header so sections below have a clear anchor.
ColumnLayout {
    id: root

    property string title: ""
    property string subtitle: ""

    Layout.fillWidth: true
    spacing: 1

    Text {
        Layout.fillWidth: true
        text: root.title
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
        color: Theme.text
    }

    Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: Theme.subtext0
    }
}
