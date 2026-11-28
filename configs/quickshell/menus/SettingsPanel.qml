import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// SUPER+comma (or click the clock): the desktop's settings on a low-poly card.
// Up/Down picks a row, Left/Right changes it, Enter presses a button, Esc
// closes. Every change is saved and applied at once (Settings.qml → apply.py).
PanelWindow {
    id: win
    visible: Menus.settingsOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "cozy-archive:settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property int rowHeight: 8 * Theme.unit
    readonly property int labelWidth: 24 * Theme.unit
    implicitWidth: 120 * Theme.unit + Theme.shadowOffset
    implicitHeight: card.height + Theme.shadowOffset

    // Each row: a label, its choices (value + words), and how to read/write it.
    // A row with one choice and an `act` is a button instead.
    readonly property var settingRows: [
        { label: "Mode",
          choices: [["light", "Day"], ["dark", "Night"]],
          get: () => Settings.mode, set: v => Settings.mode = v },
        { label: "Keyboard",
          choices: [["qwerty", "QWERTY"], ["dvorak", "Dvorak"], ["dvorak-native", "Dvorak keyboard"]],
          get: () => Settings.keyboard, set: v => Settings.keyboard = v },
        { label: "Clock",
          choices: [[false, "12-hour"], [true, "24-hour"]],
          get: () => Settings.clock24h, set: v => Settings.clock24h = v },
        { label: "Wallpaper",
          choices: [[null, "Grow new vines"]],
          act: () => Settings.wallpaperSeed = Settings.wallpaperSeed + 1 },
        { label: "Colors",
          choices: [[null, "Edit the palette"]],
          act: () => Menus.toggleColors() },
    ]
    property int focusRow: 0

    function step(row, dir) {
        const r = settingRows[row]
        if (r.act) return
        const values = r.choices.map(c => c[0])
        const i = values.indexOf(r.get())
        r.set(values[Math.max(0, Math.min(values.length - 1, i + dir))])
    }

    onVisibleChanged: if (visible) keys.forceActiveFocus()

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const r = win.settingRows[win.focusRow]
            if (event.key === Qt.Key_Escape) Menus.settingsOpen = false
            else if (event.key === Qt.Key_Down) win.focusRow = Math.min(win.settingRows.length - 1, win.focusRow + 1)
            else if (event.key === Qt.Key_Up) win.focusRow = Math.max(0, win.focusRow - 1)
            else if (event.key === Qt.Key_Left) win.step(win.focusRow, -1)
            else if (event.key === Qt.Key_Right) win.step(win.focusRow, 1)
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && r.act) r.act()
            else return
            event.accepted = true
        }
    }

    Card {
        id: card
        width: win.implicitWidth - Theme.shadowOffset
        height: 2 * Theme.borderWidth + 4 * Theme.unit
              + 7 * Theme.unit                                   // title
              + win.settingRows.length * win.rowHeight
              + 7 * Theme.unit                                   // hint

        Column {
            anchors.fill: parent
            anchors.margins: 2 * Theme.unit

            Text {
                height: 7 * Theme.unit
                leftPadding: 2 * Theme.unit
                verticalAlignment: Text.AlignVCenter
                text: "Settings"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Theme.textPrimary
            }

            Repeater {
                model: win.settingRows
                delegate: Item {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property bool focused: win.focusRow === index

                    width: parent.width
                    height: win.rowHeight

                    // Focused row: the same solid marker as the active workspace.
                    Rectangle {
                        visible: rowItem.focused
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.borderWidth
                        height: 4 * Theme.unit
                        color: Theme.focusBorder
                    }

                    Text {
                        x: 2 * Theme.unit
                        anchors.verticalCenter: parent.verticalCenter
                        text: rowItem.modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.textSecondary
                    }

                    Row {
                        x: win.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * Theme.unit

                        Repeater {
                            model: rowItem.modelData.choices
                            delegate: Card {
                                id: chip
                                required property var modelData
                                readonly property bool chosen: !rowItem.modelData.act
                                    && rowItem.modelData.get() === modelData[0]

                                // A chosen option is a raised, filled plate; the
                                // others are flat words on the card.
                                chamfer: Theme.unit
                                dropShadow: chosen || !!rowItem.modelData.act
                                fill: chosen ? Theme.accentSolid : Theme.bgPrimary
                                lit: chosen || rowItem.modelData.act ? Theme.highlight : Theme.bgPrimary
                                shade: chosen || rowItem.modelData.act ? Theme.shadow : Theme.bgPrimary
                                width: label.implicitWidth + 6 * Theme.unit
                                height: 6 * Theme.unit

                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    text: chip.modelData[1]
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    color: chip.chosen ? Theme.textOnAccent : Theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.focusRow = rowItem.index
                                        if (rowItem.modelData.act) rowItem.modelData.act()
                                        else rowItem.modelData.set(chip.modelData[0])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                height: 7 * Theme.unit
                leftPadding: 2 * Theme.unit
                verticalAlignment: Text.AlignVCenter
                text: "Arrow keys change settings. Esc closes."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Theme.textSecondary
            }
        }
    }
}
