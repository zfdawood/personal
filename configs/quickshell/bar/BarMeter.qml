import QtQuick
import ".."

// A short mono label and a proportionally-filled track, set into the card
// like a recess. No icon, no percentage: reads as an instrument.
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

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 12 * Theme.unit
        height: 2 * Theme.unit
        radius: Theme.radius
        color: Theme.bgAlt
        border.width: Theme.borderThin
        border.color: Theme.border

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: Theme.borderThin
            width: Math.max(0, (parent.width - 2 * Theme.borderThin) * Math.max(0, Math.min(1, meter.value)))
            radius: Theme.radius
            color: meter.fillColor
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }
    }
}
