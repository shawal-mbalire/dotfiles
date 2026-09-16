import QtQuick
import QtQuick.Layouts
import ".."
import "../../domain"

// Reusable base for bar-spawned menus.  Provides consistent width and spacing.
// Use Divider and Section inline where needed — they don't propagate through Loaders.
ColumnLayout {
    id: root

    implicitWidth: 296
    spacing: 8
}
