import QtQuick
import Quickshell
import ".."

// Date and time written out the way you'd say them: "Saturday 14 November, 5:10 pm"
// (or "…, 17:10" with Theme.clock24h).
Text {
    id: clock
    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    text: Qt.formatDateTime(sysClock.date,
                            Theme.clock24h ? "dddd d MMMM, HH:mm" : "dddd d MMMM, h:mm ap")

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }
}
