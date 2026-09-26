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
tokens.toml         ← every color: swatches → roles (light/dark) → terminal
templates/          ← mako.config (mako has no include, so it's templated whole)
tools/              ← gen.py (tokens → configs), contrast.py (WCAG check)
configs/
  quickshell/
    Theme.qml       ← structure (borders, sizes, fonts), darkMode, role names
    Palette.qml     ← GENERATED light/dark role colors
    Audio.qml       ← default-sink volume/mute  (singleton)
    Sys.qml         ← cpu + ram from /proc       (singleton)
    shell.qml       ← entry point
    bar/            ← Bar, Workspaces, Clock, BarMeter, StatusDot
  hypr/             ← hyprland.conf, hyprpaper.conf, colors.conf (GENERATED)
  kitty/            ← kitty.conf, colors.conf (GENERATED)
  mako/             ← config (GENERATED from templates/mako.config)
```

**To change a color, edit `tokens.toml`, then `make`.** Quickshell, Hyprland,
kitty and mako all derive from it; no hex codes are hardcoded anywhere else.
Generated files are committed, so `./install.sh` works on a fresh clone, and
`make check` fails if they've drifted from the tokens.

## Dependencies

Hyprland (>0.55), Quickshell (>0.3.0), hyprpaper, kitty, mako, wofi.
On Arch: `sudo pacman -S hyprland kitty mako hyprpaper wofi` and Quickshell from
the AUR (`yay -S quickshell`). Optional: nautilus (bound to `SUPER+E`).

## Install

```sh
./install.sh
```

Backs up any existing `~/.config/{hypr,quickshell,kitty,mako}` to `*.bak-<timestamp>`
before copying. If Departure Mono is in `~/.local/share/fonts`, it's copied into
the Quickshell config; otherwise the installer prints how to fetch it. Then log
into Hyprland.

## Tokens and checks

```sh
make           # regenerate configs/ from tokens.toml
make check     # generated files are current + WCAG contrast of every text color
make preview   # truecolor sample of the terminal palette on its own background
make hooks     # once per clone: run `make check` before every commit
make install   # make + ./install.sh
```

Contrast rules live in `tools/contrast.py` as data (`fg on bg ≥ ratio, why`),
checked against the terminal colors and both role sets. Tweak colors freely;
the check only says whether the result is still readable.

## Toggling dark mode

Edit `~/.config/quickshell/Theme.qml`: `property bool darkMode: true`.
Quickshell hot-reloads — the whole shell swaps instantly. (Hyprland, kitty and
mako use the light roles; a dark terminal palette and a single tokens-level
mode switch are follow-ups.)

## Status

First working build: top bar (workspaces, clock, cpu/ram/vol meters, status
dot) + Hyprland/kitty/mako theming. Not yet built: app launcher styling,
notification-center panel, on-screen-display (volume/brightness) popups, dark
variants of the Hyprland/kitty configs.

## License

GPL-3.0 — see [LICENSE](LICENSE).
