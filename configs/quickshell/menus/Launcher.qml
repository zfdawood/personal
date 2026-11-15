import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// SUPER+Space: an app launcher on a low-poly card. Type to filter, Up/Down to
// choose, Enter to open, Esc to close.
PanelWindow {
    id: win
    visible: Menus.launcherOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "cozy-archive:launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property int rows: 8
    readonly property int rowHeight: 6 * Theme.unit
    implicitWidth: 120 * Theme.unit + Theme.shadowOffset
    implicitHeight: card.height + Theme.shadowOffset

    // ── matching ──
    // Prefix beats word-start beats substring beats letters-in-order; ties
    // go alphabetically. Hidden entries (NoDisplay) never show.
    property string query: ""
    property int selected: 0

    function score(name, q) {
        const n = name.toLowerCase()
        if (!q) return 1
        if (n.startsWith(q)) return 4
        if (n.includes(" " + q)) return 3
        if (n.includes(q)) return 2
        let i = 0
        for (const ch of n) if (ch === q[i]) i++
        return i === q.length ? 1 : 0
    }

    readonly property var matches: {
        const q = query.trim().toLowerCase()
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ entry: e, s: score(e.name, q) }))
            .filter(m => m.s > 0)
            .sort((a, b) => b.s - a.s || a.entry.name.localeCompare(b.entry.name))
            .map(m => m.entry)
    }
    // Keep the selection on screen: the list scrolls a row at a time.
    property int first: 0
    onSelectedChanged: {
        if (selected < first) first = selected
        if (selected >= first + rows) first = selected - rows + 1
    }
    onQueryChanged: { selected = 0; first = 0 }

    onVisibleChanged: if (visible) {
        query = ""
        input.text = ""
        input.forceActiveFocus()
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        Menus.launcherOpen = false
    }

    Card {
        id: card
        width: win.implicitWidth - Theme.shadowOffset
        height: 2 * Theme.borderWidth + 4 * Theme.unit            // padding
              + 7 * Theme.unit                                    // search slot
              + 2 * Theme.unit                                    // gap
              + win.rows * win.rowHeight

        Column {
            anchors.fill: parent
            anchors.margins: 2 * Theme.unit
            spacing: 2 * Theme.unit

            // ── search: a slot cut into the card ──
            Rectangle {
                width: parent.width
                height: 7 * Theme.unit
                color: Theme.bgAlt
                Rectangle { width: parent.width; height: Theme.borderThin; color: Theme.borderShade }
                Rectangle { width: Theme.borderThin; height: parent.height; color: Theme.borderShade }
                Rectangle { y: parent.height - Theme.borderThin; width: parent.width; height: Theme.borderThin; color: Theme.highlight }
                Rectangle { x: parent.width - Theme.borderThin; width: Theme.borderThin; height: parent.height; color: Theme.highlight }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 2 * Theme.unit
                    anchors.rightMargin: 2 * Theme.unit
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.textPrimary
                    selectionColor: Theme.accentSolid
                    selectedTextColor: Theme.onAccentSolid
                    onTextChanged: win.query = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !input.text
                        text: "Type an app name"
                        font: input.font
                        color: Theme.textTertiary
                    }

                    Keys.onPressed: event => {
                        const n = win.matches.length
                        if (event.key === Qt.Key_Escape) {
                            Menus.launcherOpen = false
                        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                            if (n) win.selected = Math.min(n - 1, win.selected + 1)
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                            win.selected = Math.max(0, win.selected - 1)
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            win.launch(win.matches[win.selected])
                        } else {
                            return
                        }
                        event.accepted = true
                    }
                }
            }

            // ── results ──
            Item {
                width: parent.width
                height: win.rows * win.rowHeight

                Text {
                    visible: win.matches.length === 0
                    anchors.left: parent.left
                    anchors.leftMargin: 2 * Theme.unit
                    y: (win.rowHeight - height) / 2
                    text: "No app matches “" + win.query.trim() + "”"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.textSecondary
                }

                Repeater {
                    model: win.matches.slice(win.first, win.first + win.rows)
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: win.first + index === win.selected

                        y: index * win.rowHeight
                        width: parent.width
                        height: win.rowHeight
                        color: current ? Theme.accentSolid : "transparent"

                        Text {
                            id: name
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 2 * Theme.unit
                            text: row.modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: row.current ? Theme.onAccentSolid : Theme.textPrimary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 2 * Theme.unit
                            visible: !row.current && text !== "" && text !== row.modelData.name
                            text: row.modelData.genericName
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: win.selected = win.first + row.index
                            onClicked: win.launch(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
