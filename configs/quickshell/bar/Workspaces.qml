import QtQuick
import Quickshell.Hyprland
import ".."

// Workspaces 1–5 as plain numerals. The active one gets a solid bar under it;
// occupied ones are in full ink, empty ones faded. A fixed 1..count row reads
// as a fixed set of drawers rather than a shifting list. Click to switch.
Row {
    id: strip
    spacing: Theme.unit

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
        delegate: Item {
            id: cell
            required property int index
            readonly property int wsId: index + 1

            readonly property var hlWs:
                Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool occupied: hlWs !== null
            readonly property bool active: strip.shownWorkspace?.id === wsId

            width: 4 * Theme.unit
            height: 5 * Theme.unit

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: cell.wsId
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: cell.active || cell.occupied ? Theme.textPrimary : Theme.textTertiary
            }

            // The marker: a solid bar for the active workspace.
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3 * Theme.unit
                height: Theme.borderWidth
                color: Theme.focusBorder
                visible: cell.active
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // 0.57: `dispatch` takes a Lua dispatcher expression, not hyprlang
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + cell.wsId + " })")
            }
        }
    }
}
