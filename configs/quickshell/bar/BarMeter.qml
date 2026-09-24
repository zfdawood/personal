import QtQuick
import ".."

// A thin rectangular "instrument readout" — a short mono label and a
// proportionally-filled bar. No icon, no percentage: reads as equipment.
Row {
    id: meter
    spacing: 6
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    property string label: ""
    property real value: 0.0                 // 0.0–1.0
    property color fillColor: Theme.accent
    property int trackWidth: 44

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: meter.label
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: meter.trackWidth
        height: 8
        radius: Theme.radius
        color: Theme.bgAlt
        border.width: Theme.borderThin
        border.color: Theme.border

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: Math.max(0, (parent.width - 2) * Math.max(0, Math.min(1, meter.value)))
            radius: Theme.radius
            color: meter.fillColor
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }
    }
}
