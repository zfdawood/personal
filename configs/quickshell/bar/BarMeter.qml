import QtQuick
import ".."

// A short mono label and a proportionally-filled track, cut into the card
// like a slot. No icon, no percentage: reads as an instrument.
Row {
    id: meter
    spacing: Theme.labelGap
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    property string label: ""
    property real value: 0.0                 // 0.0–1.0
    property color fillColor: Theme.accent

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: meter.label
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    // A slot cut into the card. Light from the top left means the slot's
    // top/left inner walls are in shadow and its bottom/right walls catch light.
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 12 * Theme.unit
        height: 2 * Theme.unit
        radius: Theme.radius
        color: Theme.bgAlt

        Rectangle {
            id: fill
            x: Theme.borderThin
            y: Theme.borderThin
            height: parent.height - 2 * Theme.borderThin
            width: Math.max(0, (parent.width - 2 * Theme.borderThin) * Math.max(0, Math.min(1, meter.value)))
            radius: Theme.radius
            color: meter.fillColor
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            // Sheen: the fill's top row, a touch lighter.
            Rectangle {
                width: parent.width; height: 1
                color: Qt.lighter(meter.fillColor, 1.15)
            }
        }

        // Walls, drawn over the fill so it sits inside the slot.
        Rectangle { x: 0; y: 0; width: track.width; height: Theme.borderThin; color: Theme.borderShade }
        Rectangle { x: 0; y: 0; width: Theme.borderThin; height: track.height; color: Theme.borderShade }
        Rectangle { x: 0; y: track.height - Theme.borderThin; width: track.width; height: Theme.borderThin; color: Theme.highlight }
        Rectangle { x: track.width - Theme.borderThin; y: 0; width: Theme.borderThin; height: track.height; color: Theme.highlight }
    }
}
