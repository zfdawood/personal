# personal

Everything that wears Z. Dawood's look, from one `tokens.toml`:

| Path | What |
|---|---|
| `configs/`, `tools/`, `templates/` | **Cozy Archive**, the Hyprland + Quickshell desktop (below) |
| `web/` | The brand for web pages, GENERATED: `brand.css`, `theme.js`, `Brand.elm`, glyphs |
| `editors/` | Zed and VS Code themes, GENERATED |
| `site/` | zdawood.dev: Elm, built from `web/`, deployed by Cloudflare ([site/README.md](site/README.md)) |
| `skills/` | Claude Code skills: `personal-brand` (the brand's rules) and `written-agenda` |

Nothing generated is copied by hand: the site and the skills read `web/` in place, so a change to
`tokens.toml` reaches all of them with `make`. `make check` keeps them current and readable.

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
- **Lit from the top left.** The shadows fall down-right, so every edge
  follows the same light: borders run from a lit color (top/left) to a shaded
  one (bottom/right), cards have a 1px highlight lip, and the meters are slots
  cut into the bar. Both ends of the focused border pass the 3:1 check.
- **One spacing unit (4px).** Every gap on screen is 8px, whether between
  windows, from window to bar, or from screen edge to paper, and every size
  in the bar is a whole number of units.
- **One loud edge.** The focused window's border is amber, at a contrast of
  at least 3:1 against the paper it outlines (WCAG 1.4.11). Everything else
  is quiet.
- **Low-poly edges.** Corners are cut at 45° (Hyprland's rounding with
  `rounding_power = 1`), and every edge is a flat-shaded bevel: each face is
  shaded by how directly it faces the top-left light, so the top-left
  diagonal is brightest and the bottom-right darkest. Windows, the bar and
  the menus all follow the same rule.
- **A wooden desk, drawn by code.** `tools/wallpaper.py` paints low-poly
  planks and seeded vines at a quarter of screen resolution, dithers each
  material to its own palette ramp, and the desktop shows it at exactly 4×,
  so one wallpaper pixel is one 4px unit. Same seed, same picture.
- **Departure Mono at 11px.** It's a pixel font drawn on an 11px grid, so the
  bar uses that one size and builds hierarchy from color instead.
- **Bar-graph meters, not icons**: cpu / ram / volume as proportional fills.
- **Workspaces as numerals**, with a solid bar under the active one; empty
  workspaces are faded.
- **Settings menu** (SUPER+comma, or click the clock): day/night, keyboard
  layout, 12/24-hour clock, and "grow new vines". Changes apply at once.
- **App launcher** (SUPER+Space): type to filter, arrows to choose, Enter to open.

## Structure

```
tokens.toml         ← every color: swatches → roles (light/dark) → terminal
templates/          ← mako.config (mako has no include, so it's templated whole)
tools/              ← gen.py (tokens → configs), contrast.py (contrast + surface checks)
                       apply.py (settings → running desktop), wallpaper.py
configs/
  quickshell/
    Theme.qml       ← structure (spacing unit, borders, fonts), role names
    Tokens.qml      ← GENERATED light/dark role colors
    Settings.qml    ← settings.json, live; runs apply.py on change
    Card.qml        ← the low-poly card everything is drawn on
    Background.qml  ← the wallpaper layer
    Audio.qml       ← default-sink volume/mute  (singleton)
    Sys.qml         ← cpu + ram from /proc       (singleton)
    shell.qml       ← entry point
    bar/            ← Bar, Workspaces, Clock, BarMeter
    menus/          ← Launcher, SettingsPanel
  hypr/             ← hyprland.lua, colors.lua (GENERATED, both modes)
  kitty/            ← kitty.conf, colors-{light,dark}.conf (GENERATED)
  mako/             ← config-{light,dark} (GENERATED from templates/mako.config)
  cozy-archive/     ← settings.json defaults (GENERATED; installed once)
```

Every app ships both its day and night colors. At runtime, `apply.py` reads
`~/.config/cozy-archive/settings.json` and switches links
(`kitty/colors.conf`, `mako/config`), writes `hypr/settings.lua`, draws the
wallpaper if it isn't cached, and reloads what's running. The settings menu
runs it on every change; Hyprland runs it at login. `make install` and
`make colors` first copy `mode` from `tokens.toml` into `settings.json`, so the
versioned file decides day or night; the menu's toggle lasts until the next install.

**To change a color, edit `tokens.toml`, then `make` (and `make colors` to
deploy).** Quickshell, Hyprland,
kitty and mako all derive from it; no hex codes are hardcoded anywhere else.
Generated files are committed, so `./install.sh` works on a fresh clone, and
`make check` fails if they've drifted from the tokens.

## The brand beyond the desktop

The same `tokens.toml` also describes Z. Dawood's personal brand on the web and in
editors. `make` writes these next to the desktop configs, `make check` holds them to the
same rules (current with the tokens, and WCAG contrast for the web sheet, the editor UI
and every code color), and the same tokens always give the same bytes.

| Output | What |
|---|---|
| `web/brand.css` | Custom properties for day and night (colors, the bevel's eight faces, the desk as an inlined PNG, structure, type) + the hand-written `templates/web/components.css` |
| `web/theme.js` | The day/night switch (`templates/web/theme.js`) |
| `web/glyphs/leaf.svg` | The low-poly leaf, shaded from `[glyph]` ramps |
| `web/Brand.elm` | The web palette for both modes and the leaf, for Elm sites |
| `editors/zed/cozy-archive.json` | Zed theme family: Cozy Archive Day / Night |
| `editors/vscode/` | VS Code theme extension: Cozy Archive Day / Night |

What is computed rather than listed, so every output gets the same answer:
- **The bevel**: each face is lit by how directly it faces the top-left light (Lambert's
  cosine, as in `Card.qml`), mixed in OKLab between `lit` and `ruleShade`.
- **The desk**: `tools/wallpaper.py` at `[structure] desk_seed` and `desk_size`, shown at `desk_scale`.
- **The leaf**: each face has a light value; a value halfway between two ramp steps becomes a
  2×2 dither of both, like the wallpaper.

Who reads them, in place: `site/` (its build copies `web/` into `dist/`, and `elm.json` lists
`../web`) and `skills/` (the agenda renderer inlines `web/brand.css`).

```sh
make site     # build zdawood.dev and serve it at http://localhost:8000
make skills   # link skills/* into ~/.claude/skills (SKILLS=… to change)
make zed      # → ~/.config/zed/themes (ZED_THEMES=… to change)
make vscode   # → ~/.vscode/extensions/… (VSCODE_EXT=… to change)
```

Hand-written, and read only through generated variables: `templates/web/components.css`
(the sheet, chips, ledger, fold-outs) and `templates/web/theme.js`.

## Dependencies

Hyprland (≥0.57, which reads only the Lua config), Quickshell (>0.3.0),
kitty, mako, Python 3.11+ (stdlib only: wallpaper and settings). On Arch, all
from the official repos: `sudo pacman -S hyprland quickshell kitty mako python nautilus`.
nautilus is bound to `SUPER+E` (vm-guest-setup.sh installs it). `make fonts`
fetches the brand's fonts (JetBrains Mono, Newsreader, Kalam, Archivo).

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
