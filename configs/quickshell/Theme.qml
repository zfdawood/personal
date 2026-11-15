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
    // Follows the settings menu (SUPER+comma), which writes settings.json;
    // tokens.toml's `mode` is only the default for a fresh install.
    readonly property bool darkMode: Settings.mode === "dark"

    // ── Spacing: one 4px unit ───────────────────────────────────────────────
    // Every size below is a whole number of units, and the gaps match
    // Hyprland's (gaps_out = 8, two windows sit 8 apart), so the bar and the
    // windows share one grid. Change `unit` and everything scales together.
    readonly property int unit: 4
    readonly property int gap:          2 * unit   // between any two papers; bar ↔ screen edge
    readonly property int shadowOffset: unit       // hard shadow, down-right (= Hyprland's)
    readonly property int barHeight:    7 * unit   // the bar card, border included
    readonly property int padX:         3 * unit   // inside the bar card, left/right
    readonly property int groupGap:     6 * unit   // between meters
    readonly property int labelGap:     2 * unit   // label → its meter
    readonly property int chamfer:      2 * unit   // cut corners (= Hyprland's rounding 8, power 1)

    // Borders: the same 2px as Hyprland's windows; 1px only for recesses.
    readonly property int borderWidth: 2
    readonly property int borderThin:  1
    readonly property int radius: 0    // square corners, everywhere

    // Optional CRT scanline overlay — OFF by default (readability first).
    property bool scanlines: false
    property real scanlineOpacity: 0.06

    // ── Typography ──────────────────────────────────────────────────────────
    // Departure Mono is the target (chunky, pixel-ish, closest to Signalis).
    // Falls back cleanly to JetBrains Mono if the otf isn't installed yet.
    readonly property string fontFamily: monoFont.status === FontLoader.Ready
        ? monoFont.name
        : "JetBrains Mono"
    // Departure Mono is a pixel font drawn on an 11px grid: it's only crisp at
    // 11px (or 22, 33…), so there's one size, and hierarchy comes from color.
    readonly property int fontSize: 11

    // ── Clock ───────────────────────────────────────────────────────────────
    readonly property bool clock24h: Settings.clock24h   // false: "5:10 pm"; true: "17:10"

    FontLoader {
        id: monoFont
        // Copied in by install.sh from ~/.local/share/fonts if present;
        // harmless if absent (fallback kicks in).
        source: Qt.resolvedUrl("fonts/DepartureMono-Regular.otf")
    }

    // ── Palette ─────────────────────────────────────────────────────────────
    // Both mode sets are generated from tokens.toml into Tokens.qml; edit the
    // tokens (then `make`), not hex codes here.
    readonly property var  set:            darkMode ? Tokens.dark : Tokens.light
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
    readonly property color desk:          set.desk          // what the papers lie on
    readonly property color shadow:        set.shadow        // hard card shadow
    // Light from the top left: lit edges top/left, shaded edges bottom/right.
    readonly property color focusBorder:      set.focusBorder
    readonly property color focusBorderShade: set.focusBorderShade
    readonly property color borderShade:      set.borderShade
    readonly property color highlight:        set.highlight   // 1px lit lip inside a card
}
