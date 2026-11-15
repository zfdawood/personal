# Warm Terminal / Cozy Archive

A Hyprland + Quickshell desktop theme: Signalis-style retro-terminal UI bones
(square panels, monospace type, instrument-panel meters) in a warm
library/archive palette — parchment, rust amber, dusty rose, sage moss. Minus
the horror, minus the clinical grey-and-red.

## Look

- **Paper on a desk.** Windows and the bar are parchment cards lying on a
  darker desk, each with a hard offset shadow (no blur). The step between desk
  and paper is measured, not eyeballed: `make check` holds it to a minimum
  OKLab lightness difference in both modes.
- **One spacing unit (4px).** Every gap on screen is 8px, whether between
  windows, from window to bar, or from screen edge to paper, and every size
  in the bar is a whole number of units.
- **One loud edge.** The focused window's border is amber, at a contrast of
  at least 3:1 against the paper it outlines (WCAG 1.4.11). Everything else
  is quiet.
- **Square corners everywhere** and 2px borders, the same on windows and the bar.
- **Departure Mono at 11px.** It's a pixel font drawn on an 11px grid, so the
  bar uses that one size and builds hierarchy from color instead.
- **Bar-graph meters, not icons**: cpu / ram / volume as proportional fills.
- **Workspaces as numerals**, with a solid bar under the active one; empty
  workspaces are faded.
- **Light "day archive" by default**; one switch in `tokens.toml` for "night archive".

## Structure

```
tokens.toml         ← every color: swatches → roles (light/dark) → terminal
templates/          ← mako.config (mako has no include, so it's templated whole)
tools/              ← gen.py (tokens → configs), contrast.py (WCAG check)
configs/
  quickshell/
    Theme.qml       ← structure (borders, sizes, fonts), darkMode, role names
    Tokens.qml      ← GENERATED light/dark role colors
    Audio.qml       ← default-sink volume/mute  (singleton)
    Sys.qml         ← cpu + ram from /proc       (singleton)
    shell.qml       ← entry point
    bar/            ← Bar, Workspaces, Clock, BarMeter
  hypr/             ← hyprland.lua, hyprpaper.conf, colors.lua (GENERATED)
  kitty/            ← kitty.conf, colors.conf (GENERATED)
  mako/             ← config (GENERATED from templates/mako.config)
```

**To change a color, edit `tokens.toml`, then `make`.** Quickshell, Hyprland,
kitty and mako all derive from it; no hex codes are hardcoded anywhere else.
Generated files are committed, so `./install.sh` works on a fresh clone, and
`make check` fails if they've drifted from the tokens.

## Dependencies

Hyprland (≥0.57, which reads only the Lua config), Quickshell (>0.3.0), hyprpaper,
kitty, mako, wofi. On Arch, all from the official repos:
`sudo pacman -S hyprland quickshell kitty mako hyprpaper wofi`.
Optional: nautilus (bound to `SUPER+E`).

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
make colors    # make + redeploy just the color files, reload running apps
make install   # make + full ./install.sh
```

Contrast rules live in `tools/contrast.py` as data (`fg on bg ≥ ratio, why`),
checked against the terminal colors and both role sets. Tweak colors freely;
the check only says whether the result is still readable.

## Day / night

Set `mode = "dark"` (or `"light"`) at the top of `tokens.toml`, then:

```sh
make colors    # regenerate + redeploy only the color files, reload running apps
```

Quickshell, Hyprland, kitty and mako all switch together. `make colors` touches
only generated files, so it never backs anything up or overwrites hand edits to
your installed configs. `make check` verifies both modes regardless of which one
is active.

## Status

See [ROADMAP.md](ROADMAP.md) for what's built and what a daily driver still needs.

## License

GPL-3.0 — see [LICENSE](LICENSE).
