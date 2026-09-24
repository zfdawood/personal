import QtQuick
import Quickshell
import ".."

// Monospace "readout label" clock. Sentence case, no ALL CAPS.
Text {
    id: clock
    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    text: Qt.formatDateTime(sysClock.date, "ddd d MMM  ·  HH:mm")

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }
}
