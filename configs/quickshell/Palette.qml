// GENERATED from tokens.toml by tools/gen.py — edit tokens.toml, then run `make`.
// Theme.qml picks light or dark from here; components read Theme, not this.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // tokens.toml `mode`; Theme.darkMode follows it.
    readonly property bool darkMode: false
    readonly property var light: ({
        bgPrimary:     "#F3E9D8",
        bgAlt:         "#E3D5B8",
        border:        "#C9B896",
        borderStrong:  "#8A7654",
        textPrimary:   "#2B2420",
        textSecondary: "#5C4A2E",
        textTertiary:  "#8A7654",
        accent:        "#C97B3D",
        warning:       "#B5654F",
        good:          "#7C8B6F",
        media:         "#B5654F",
        accentSolid:   "#8A5327",
        onAccentSolid: "#F3E9D8",
        scanline:      "#000000"
    })
    readonly property var dark: ({
        bgPrimary:     "#2B2420",
        bgAlt:         "#1C1713",
        border:        "#4A3F35",
        borderStrong:  "#8A7654",
        textPrimary:   "#F3E9D8",
        textSecondary: "#C9B896",
        textTertiary:  "#8A7654",
        accent:        "#C97B3D",
        warning:       "#B5654F",
        good:          "#7C8B6F",
        media:         "#B5654F",
        accentSolid:   "#C97B3D",
        onAccentSolid: "#2B2420",
        scanline:      "#000000"
    })
}
