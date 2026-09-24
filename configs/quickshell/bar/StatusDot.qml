import QtQuick
import ".."

// 8x8 solid square status indicator. `filled` false → outline only.
Rectangle {
    id: dot
    property color tint: Theme.accent
    property bool filled: true

    width: Theme.dotSize
    height: Theme.dotSize
    radius: Theme.radius
    color: filled ? tint : "transparent"
    border.width: filled ? 0 : Theme.borderThin
    border.color: tint
}
