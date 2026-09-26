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

    // The Hyprland monitor this bar sits on; falls back to the global focus
    // if it can't be matched (e.g. before the first IPC refresh).
    readonly property var monitor:
        Hyprland.monitors.values.find(m => m.name === strip.screenName) ?? null
    readonly property var shownWorkspace:
        monitor?.activeWorkspace ?? Hyprland.focusedWorkspace

    Repeater {
        model: strip.count
        delegate: Rectangle {
            id: sq
            required property int index
            readonly property int wsId: index + 1

            readonly property var hlWs:
                Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool occupied: hlWs !== null
            readonly property bool active: strip.shownWorkspace?.id === wsId

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
