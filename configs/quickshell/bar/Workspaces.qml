import QtQuick
import Quickshell.Hyprland
import ".."

// Numbered squares: filled solid on active, outlined when occupied, faint
// when empty. Click to switch. A fixed 1..count row reads as an instrument
// panel rather than a shifting list.
Row {
    id: strip
    spacing: 4

    property int count: 5
    property string screenName: ""

    Repeater {
        model: strip.count
        delegate: Rectangle {
            id: sq
            required property int index
            readonly property int wsId: index + 1

            readonly property var hlWs:
                Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool occupied: hlWs !== null
            readonly property bool active:
                Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

            width: 16
            height: 16
            radius: Theme.radius
            color: active ? Theme.accent : "transparent"
            border.width: active ? 0 : (occupied ? Theme.borderWidth : Theme.borderThin)
            border.color: occupied ? Theme.textSecondary : Theme.border

            Text {
                anchors.centerIn: parent
                text: sq.wsId
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: sq.active
                    ? Theme.bgPrimary
                    : (sq.occupied ? Theme.textPrimary : Theme.textTertiary)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + sq.wsId)
            }
        }
    }
}
