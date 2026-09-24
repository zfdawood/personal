# Warm Terminal / Cozy Archive

A Hyprland + Quickshell desktop theme: Signalis-style retro-terminal UI bones
(square panels, monospace type, instrument-panel meters) in a warm
library/archive palette — parchment, rust amber, dusty rose, sage moss. Minus
the horror, minus the clinical grey-and-red.

## Look

- **Square corners everywhere** (`radius: 0`), thick 2px borders — panels read
  as physical equipment casing, not flat modern cards.
- **Monospace everywhere** — Departure Mono (falls back to JetBrains Mono).
- **Bar-graph meters, not icons** — cpu / ram / volume as proportional fill bars.
- **Workspaces as numbered squares** — filled on active, outlined when occupied.
- **8×8 square status dots** instead of status glyphs.
- **Light "day archive" by default**; flip `Theme.darkMode` for "night archive".

## Structure

```
configs/
  quickshell/
    Theme.qml       ← the single source of truth: palette, borders, fonts, darkMode
    Audio.qml       ← default-sink volume/mute  (singleton)
    Sys.qml         ← cpu + ram from /proc       (singleton)
    shell.qml       ← entry point
    bar/            ← Bar, Workspaces, Clock, BarMeter, StatusDot
  hypr/             ← hyprland.conf (square, amber borders), hyprpaper.conf
  kitty/            ← warm terminal palette
  mako/             ← notification toasts
```

**To restyle anything, edit `Theme.qml`.** Every component reads that singleton
— no hex codes are hardcoded elsewhere. That's what makes the light/dark toggle
and future palette tweaks one-file changes.

## Dependencies

Hyprland (>0.55), Quickshell (>0.3.0), hyprpaper, kitty, mako, wofi.
On Arch: `sudo pacman -S hyprland kitty mako hyprpaper wofi` and Quickshell from
the AUR (`yay -S quickshell`).

## Install

```sh
./install.sh
```

Backs up any existing `~/.config/{hypr,quickshell,kitty,mako}` to `*.bak-<timestamp>`
before copying. Then log into Hyprland.

## Toggling dark mode

Edit `~/.config/quickshell/Theme.qml`: `property bool darkMode: true`.
Quickshell hot-reloads — the whole shell swaps instantly. (Hyprland/kitty border
colors are set per-config; a matching dark set is a follow-up.)

## Status

First working build: top bar (workspaces, clock, cpu/ram/vol meters, status
dot) + Hyprland/kitty/mako theming. Not yet built: app launcher styling,
notification-center panel, on-screen-display (volume/brightness) popups, dark
variants of the Hyprland/kitty configs.
