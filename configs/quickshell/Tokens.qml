// GENERATED from tokens.toml by tools/gen.py — edit tokens.toml, then run `make`.
// Theme.qml picks light or dark from here; components read Theme, not this.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // tokens.toml `mode`; Theme.darkMode follows it.
    readonly property bool darkMode: false
    // [structure]: Theme.qml sizes everything in these.
    readonly property int unit: 4
    readonly property int cut: 2
    readonly property int shadow: 1
    // [type]: the first family of each stack.
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontText: "Newsreader"
    readonly property string fontHand: "Kalam"
    readonly property string fontHead: "Archivo"
    readonly property var light: ({
        bgPrimary:        "#F3E9D8",
        bgAlt:            "#E3D5B8",
        border:           "#C9B896",
        borderStrong:     "#8A7654",
        textPrimary:      "#2B2420",
        textSecondary:    "#5C4A2E",
        textTertiary:     "#8A7654",
        accent:           "#5A3D94",
        warning:          "#B5654F",
        alert:            "#904E3D",
        good:             "#7C8B6F",
        media:            "#B5654F",
        accentSolid:      "#5A3D94",
        onAccentSolid:    "#F3E9D8",
        scanline:         "#000000",
        desk:             "#B39C78",
        shadow:           "#7A6646",
        focusBorder:      "#AD3A6C",
        focusBorderShade: "#8A2D56",
        borderShade:      "#B9A684",
        highlight:        "#FBF6EC",
        pencil:           "#5A3D94"
    })
    readonly property var dark: ({
        bgPrimary:        "#2B2420",
        bgAlt:            "#1C1713",
        border:           "#4A3F35",
        borderStrong:     "#8A7654",
        textPrimary:      "#F3E9D8",
        textSecondary:    "#C9B896",
        textTertiary:     "#8A7654",
        accent:           "#BBA5E8",
        warning:          "#B5654F",
        alert:            "#C88E7D",
        good:             "#7C8B6F",
        media:            "#B5654F",
        accentSolid:      "#BBA5E8",
        onAccentSolid:    "#2B2420",
        scanline:         "#000000",
        desk:             "#120E0B",
        shadow:           "#000000",
        focusBorder:      "#E58BB0",
        focusBorderShade: "#BF4A7E",
        borderShade:      "#3A3129",
        highlight:        "#3A3129",
        pencil:           "#BBA5E8"
    })
}
