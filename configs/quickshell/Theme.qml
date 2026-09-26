pragma Singleton

import QtQuick
import Quickshell

// ── Warm Terminal / Cozy Archive ────────────────────────────────────────────
// What every component reads: e.g. `Theme.bgPrimary`, never a hardcoded hex.
// Structure (borders, sizes, fonts) is set here; colors come from tokens.toml.
// `darkMode` swaps the shell between "day archive" (parchment) and "night
// archive" (deep umber); it and all colors come from tokens.toml.
Singleton {
    id: root

    // ── Mode ────────────────────────────────────────────────────────────────
    // Follows `mode` in tokens.toml (the one switch for every app) — change it
    // there and `make install`, rather than here.
    readonly property bool darkMode: Palette.darkMode

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
    // Both mode sets are generated from tokens.toml into Palette.qml; edit the
    // tokens (then `make`), not hex codes here.
    readonly property var  set:            darkMode ? Palette.dark : Palette.light
    readonly property color bgPrimary:     set.bgPrimary
    readonly property color bgAlt:         set.bgAlt
    readonly property color border:        set.border
    readonly property color borderStrong:  set.borderStrong
    readonly property color textPrimary:   set.textPrimary
    readonly property color textSecondary: set.textSecondary
    readonly property color textTertiary:  set.textTertiary

    // Semantic roles so widgets read intent, not color.
    readonly property color accent:        set.accent          // fills: meters, focus
    readonly property color warning:       set.warning
    readonly property color good:          set.good
    readonly property color media:         set.media
    readonly property color accentSolid:   set.accentSolid     // filled surface with text on it
    readonly property color onAccentSolid: set.onAccentSolid   // …the text
    readonly property color scanline:      set.scanline
}
