pragma Singleton

import QtQuick
import Quickshell

// ── Warm Terminal / Cozy Archive ────────────────────────────────────────────
// The single source of truth for the whole desktop. Every component imports
// this singleton and reads e.g. `Theme.bgPrimary` — never a hardcoded hex.
// Flip `darkMode` and the entire shell swaps between "day archive" (parchment)
// and "night archive" (deep umber). The three accents are mode-stable by
// design, so only the base/text pair inverts.
Singleton {
    id: root

    // ── The one switch ──────────────────────────────────────────────────────
    property bool darkMode: false

    // ── Structural constants (Signalis "equipment casing" bones) ────────────
    property int  borderWidth: 2        // thick, physical. inactive elems drop to borderThin
    property int  borderThin: 1
    property int  radius: 0             // square corners are the default, everywhere
    property int  barHeight: 26
    property int  gap: 8                // base spacing unit
    property int  dotSize: 8            // the 8x8 square status indicator

    // Optional CRT scanline overlay — OFF by default (readability first).
    property bool scanlines: false
    property real scanlineOpacity: 0.06
    readonly property color scanlineColor: "#000000"

    // ── Typography ──────────────────────────────────────────────────────────
    // Departure Mono is the target (chunky, pixel-ish, closest to Signalis).
    // Falls back cleanly to JetBrains Mono if the otf isn't installed yet.
    readonly property string fontFamily: monoFont.status === FontLoader.Ready
        ? monoFont.name
        : "JetBrains Mono"
    property int fontSize: 13
    property int fontSizeSmall: 11

    FontLoader {
        id: monoFont
        // Copied in by install.sh from ~/.local/share/fonts if present;
        // harmless if absent (fallback kicks in).
        source: Qt.resolvedUrl("fonts/DepartureMono-Regular.otf")
    }

    // ── Palette ─────────────────────────────────────────────────────────────
    // Two named sets; `darkMode` picks which is dominant. Accents are shared.
    readonly property var light: ({
        bgPrimary:     "#F3E9D8",  // parchment
        bgAlt:         "#E3D5B8",  // deeper parchment — recesses, meter tracks
        border:        "#C9B896",  // hairline / inactive borders
        textPrimary:   "#2B2420",  // deep umber-black (never pure black)
        textSecondary: "#5C4A2E",  // labels, timestamps
        textTertiary:  "#8A7654"   // worn leather — hints, inactive states
    })
    readonly property var dark: ({
        bgPrimary:     "#2B2420",  // deep umber
        bgAlt:         "#1C1713",  // recesses, meter tracks
        border:        "#4A3F35",  // dividers
        textPrimary:   "#F3E9D8",  // parchment, inverted to foreground
        textSecondary: "#C9B896",  // labels
        textTertiary:  "#8A7654"   // same worn-leather anchor, both modes
    })

    // Mode-stable accents (mid-brightness — read well on parchment AND umber).
    readonly property color rustAmber: "#C97B3D"  // primary accent / "alarm color" stand-in
    readonly property color dustyRose: "#B5654F"  // secondary / warnings / media
    readonly property color sageMoss:  "#7C8B6F"  // calm / success / "everything is fine"

    // ── Resolved roles (what components actually read) ──────────────────────
    readonly property var  set:           darkMode ? dark : light
    readonly property color bgPrimary:     set.bgPrimary
    readonly property color bgAlt:         set.bgAlt
    readonly property color border:        set.border
    readonly property color textPrimary:   set.textPrimary
    readonly property color textSecondary: set.textSecondary
    readonly property color textTertiary:  set.textTertiary

    // Semantic aliases so widgets read intent, not color.
    readonly property color accent:  rustAmber
    readonly property color warning: dustyRose
    readonly property color good:    sageMoss
}
