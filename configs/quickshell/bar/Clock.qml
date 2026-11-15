import QtQuick
import Quickshell
import ".."

// Date and time written out the American way, as you'd say them:
// "Saturday, November 14th at 5:10 pm" (or "… at 17:10" with Theme.clock24h).
Text {
    id: clock
    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    text: {
        const d = sysClock.date
        const day = d.getDate()
        return Qt.formatDateTime(d, "dddd, MMMM ") + day + ordinal(day)
            + " at " + Qt.formatDateTime(d, Theme.clock24h ? "HH:mm" : "h:mm ap")
    }

    // 1st 2nd 3rd 4th … 11th 12th 13th … 21st 22nd 23rd … 31st
    function ordinal(n) {
        if (n % 100 >= 11 && n % 100 <= 13) return "th"
        return ["th", "st", "nd", "rd"][n % 10] ?? "th"
    }

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }
}
