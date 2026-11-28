import QtQuick
import Quickshell

// The login card: one low-poly card shared by the lock screen (Lock.qml, PAM)
// and the boot greeter (greeter.qml, greetd). It only draws and collects
// input; whoever owns it runs the authentication and sets these:
//
//   user / userEditable   whose session; the greeter lets you type another name
//   prompt / echo         what PAM or greetd asked for ("Password"), and whether
//                         the answer is shown as typed (a username) or masked
//   message / isError     the last thing the auth stack said, or our own words
//   busy                  checking; input waits
//   buffer                the field's text, held by the owner and shared by
//                         every screen's card, so typing on any monitor fills
//                         the same answer. The card never assigns it (that
//                         would break the owner's binding); it emits
//                         `bufferEdited` and `userEdited` instead.
//
// Enter emits `submitted`; Esc clears the field. Tab moves between the user
// and answer fields when the user is editable.
Card {
    id: card

    property string user: ""
    property bool userEditable: false
    property string prompt: "Password"
    property bool echo: false
    property string message: ""
    property bool isError: false
    property bool busy: false
    property string buffer: ""
    property string hint: "Enter unlocks. Esc clears."

    signal submitted()
    signal bufferEdited(string text)
    signal userEdited(string name)

    readonly property int labelWidth: 24 * Theme.unit
    readonly property int rowHeight: 9 * Theme.unit

    width: 120 * Theme.unit
    height: 2 * Theme.borderWidth + 4 * Theme.unit
          + 18 * Theme.unit                 // the time and date, pencilled in
          + 2 * rowHeight                   // user, answer
          + 7 * Theme.unit                  // message
          + 7 * Theme.unit                  // hint

    function focusAnswer() { answer.forceActiveFocus() }
    function focusUser() { if (userEditable) userInput.forceActiveFocus(); else focusAnswer() }

    component Label: Text {
        x: 2 * Theme.unit
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.textSecondary
    }

    Column {
        anchors.fill: parent
        anchors.margins: 2 * Theme.unit

        // ── the time, large, and the date as the bar says it ──
        Text {
            height: 12 * Theme.unit
            leftPadding: 2 * Theme.unit
            verticalAlignment: Text.AlignBottom
            color: Theme.pencil
            font.family: Theme.handFamily
            font.pixelSize: 2 * Theme.handSize
            text: Qt.formatDateTime(clock.date, Theme.clock24h ? "HH:mm" : "h:mm ap")
        }
        Text {
            height: 6 * Theme.unit
            leftPadding: 2 * Theme.unit
            verticalAlignment: Text.AlignTop
            color: Theme.pencil
            font.family: Theme.handFamily
            font.pixelSize: Theme.handSize
            text: Qt.formatDateTime(clock.date, "dddd, MMMM ") + clock.date.getDate()
                + card.ordinal(clock.date.getDate())
        }

        // ── user ──
        Item {
            width: parent.width
            height: card.rowHeight
            Label { text: "User" }
            Text {
                visible: !card.userEditable
                x: card.labelWidth + 2 * Theme.unit
                anchors.verticalCenter: parent.verticalCenter
                text: card.user
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Theme.textPrimary
            }
            Slot {
                visible: card.userEditable
                x: card.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - card.labelWidth - 2 * Theme.unit
                height: 7 * Theme.unit
                TextInput {
                    id: userInput
                    anchors.fill: parent
                    anchors.leftMargin: 2 * Theme.unit
                    anchors.rightMargin: 2 * Theme.unit
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.textPrimary
                    selectionColor: Theme.accentSolid
                    selectedTextColor: Theme.textOnAccent
                    enabled: !card.busy
                    text: card.user
                    onTextEdited: card.userEdited(text)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                || event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                            card.focusAnswer()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        // ── the answer (password, or whatever the auth stack asked) ──
        Item {
            width: parent.width
            height: card.rowHeight
            Label { text: card.prompt }
            Slot {
                x: card.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - card.labelWidth - 2 * Theme.unit
                height: 7 * Theme.unit

                // The focused field gets the active workspace's marker.
                Rectangle {
                    visible: answer.activeFocus
                    x: -2 * Theme.unit
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.borderWidth
                    height: 4 * Theme.unit
                    color: Theme.focusBorder
                }

                TextInput {
                    id: answer
                    anchors.fill: parent
                    anchors.leftMargin: 2 * Theme.unit
                    anchors.rightMargin: 2 * Theme.unit
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.textPrimary
                    selectionColor: Theme.accentSolid
                    selectedTextColor: Theme.textOnAccent
                    echoMode: card.echo ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    enabled: !card.busy
                    text: card.buffer
                    onTextEdited: card.bufferEdited(text)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (!card.busy) card.submitted()
                        } else if (event.key === Qt.Key_Escape) {
                            card.bufferEdited("")
                        } else if (card.userEditable && (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up
                                || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier))) {
                            userInput.forceActiveFocus()
                        } else {
                            return
                        }
                        event.accepted = true
                    }
                }
            }
        }

        // ── what the auth stack said ──
        Text {
            height: 7 * Theme.unit
            leftPadding: 2 * Theme.unit
            verticalAlignment: Text.AlignVCenter
            text: card.busy ? "Checking…" : card.message
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: card.isError && !card.busy ? Theme.alert : Theme.textSecondary
        }

        Text {
            height: 7 * Theme.unit
            leftPadding: 2 * Theme.unit
            verticalAlignment: Text.AlignVCenter
            text: card.hint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.textSecondary
        }
    }

    function ordinal(n) {
        if (n % 100 >= 11 && n % 100 <= 13) return "th"
        return ["th", "st", "nd", "rd"][n % 10] ?? "th"
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
