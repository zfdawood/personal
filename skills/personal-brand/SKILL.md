---
name: personal-brand
description: >
  Z. Dawood's personal visual brand for anything he makes to be looked at: HTML pages, handouts,
  agendas, reports, slides, his website. Parchment on an oak desk, hard shadows, cut corners, a
  serif text face, mono headings, pencilled dates and purple/pink inks. Use whenever a page, site
  or document should look like his, or he says "my brand", "personal brand", "my style", "the
  handout look", "cozy archive". Holds the tokens and the stylesheet. NOT for client-branded work
  or DevHawk/client deliverables unless he asks.
---

# Personal brand

Z. Dawood's own look. It comes from two things he made: the **Cozy Archive** desktop theme (in his
private repo `zfdawood/personal`, checked out at `~/work/personal`, where `tokens.toml` is the source
of truth) and the **wins handout**
(`~/wins/handout/Zachariah-Dawood-Wins-Jul-Nov-2026.html`). If either changes, check this file
against it.

The stylesheet is `web/brand.css` in that repo (`~/work/personal/web/brand.css`; from this skill
folder, `../../web/brand.css`). Every page in the brand inlines it whole (or a site
links it). Don't restyle per page. Add page-specific CSS after it, built from its tokens.

## Where the brand comes from (read before changing anything)

This skill lives in the same repo (`skills/personal-brand`; `~/.claude/skills/personal-brand` is a
link to it, made by `make skills`). **`web/brand.css`, `web/theme.js`, `web/glyphs/leaf.svg` and
`web/Brand.elm` are GENERATED. Don't edit them, and don't copy them anywhere:** everything reads
them in place. The single source is `tokens.toml`:
- Colors, structure (unit, cut, bevel, page, the desk seed) and type are in `tokens.toml`
  (`[swatch]`, `[web.*]`, `[web_alpha.*]`, `[structure]`, `[type]`, `[glyph]`, `[editor.*]`, `[syntax.*]`).
- Component rules are hand-written in `templates/web/components.css`, and read only generated
  variables. The day/night script is `templates/web/theme.js`.
- `make` regenerates everything: the desktop configs, `web/brand.css`, `web/theme.js`,
  `web/glyphs/leaf.svg`, `web/Brand.elm`, the Zed theme and the VS Code theme.
  `make check` fails on stale output or on any contrast rule (web, editor, syntax, terminal).
- The site (`site/`) builds from `web/` directly; agendas read `web/brand.css` through
  `render.py`. `make zed` / `make vscode` install the editor themes (the only copies left).

So for a brand change: edit tokens.toml or the templates, run `make check`, then rebuild what uses
it (re-render agendas; `make site` to look at the site locally). A push to `main` redeploys the site.

## The look in one breath

A sheet of parchment lying on an oak desk, lit from the top left. The sheet has corners cut at 45°,
a hard shadow one unit down-right with no blur, a 2px lit lip on its top/left edge, faint paper
grain, and a pink margin rule. Text is a book serif. Top-level headings are a clean mono. Dates
are pencilled in a hand face, and accents are the purple and pink inks of the handout. It's quiet.
One thing on a page gets the highlighter.

## Tokens

| Token | Day | Night | For |
|---|---|---|---|
| `--desk` | oak `#B39C78` | ebony `#120E0B` | page background, the desk |
| `--shadow` | oak_shade `#7A6646` | `#000` | the hard offset shadow |
| `--sheet` | parchment `#F3E9D8` | umber `#2B2420` | the paper |
| `--recess` | parchment_deep `#E3D5B8` | umber_deep `#1C1713` | buttons, wells |
| `--lit` | parchment_hi `#FBF6EC` | umber_mid `#3A3129` | the lit edge lip |
| `--rule` / `--rule-shade` | straw / straw_shade | umber_line / umber_mid | hairlines, the shaded edge |
| `--ink` / `--muted` / `--faint` | umber / walnut / leather_ink | parchment / straw / leather_glow | text, labels, sources |
| `--gel` | `#5a3d94` | `#bba5e8` | purple ink: numbers, dates, asks, quotes, kickers |
| `--pink` | `#ad3a6c` | `#e58bb0` | +/− marks, link underlines, focus |
| `--hl` | pink at 24% | pink at 20% | the highlighter swipe |
| `--margin` | pink at 45% | pink at 35% | the margin rule |
| `--good` | moss_ink | moss | a passing/done state |

Spacing is one unit, `--u: 4px`. Every gap, pad and offset is a whole number of units. Corners are
cut (`--cut: 8px`), never rounded. The sheet is `--page: 1200px` wide at most. Pages use the width.

## Type

Load from Google Fonts:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..800&family=JetBrains+Mono:wght@400;600;700&family=Kalam:wght@400;700&family=Newsreader:ital,opsz,wght@0,6..72,400..700;1,6..72,400..700&display=swap" rel="stylesheet">
```

| Role | Face | Where |
|---|---|---|
| `--text` | Newsreader | running text, ledes (italic), quotes |
| `--mono` | JetBrains Mono | top-level headings (`h1`, `h2`, a list's main topics), kickers, small uppercase labels, table headers, sources |
| `--hand` | Kalam | pencilled dates and item numbers, in `--gel` |
| `--head` | Archivo | bold names inside tables and lists |

Only top-level headings go mono. Numbers stay in the hand face, and everything else keeps the face
above. He wants the mono legible, so don't swap in a pixel font (Departure Mono) for headings.

## Components in brand.css

`.paper` > `.sheet` (the sheet on the desk) · `.bevel` · `.readout` · `[data-theme-toggle]` (with `theme.js`) · `a.chip` / `button.chip` · `.tag` · `svg.glyph` · `.kicker` · `h1` / `h2` · `.byline` with `.when` ·
`.lede` · `h4` labels · `.hl` (one result per page) · `.said` (a quote) · `.ask` (a question for the
room) · `.from` (a source line) · `button.chip` · `.tablewrap` > `table` (a ledger, `td.num` for
figures, `td b` for row names) · `details` with a `.mark` +/− · `footer` (sits on the desk under the
sheet).

## Rules

- Both modes always: the tokens already switch for `prefers-color-scheme` and `data-theme`.
- A page meant to be opened locally is a full HTML document (`<!doctype html>`, `<html lang="en">`,
  head with charset and viewport). Write it to a file. Don't publish it as an artifact unless he asks.
- His name on any page is **Z. Dawood** (`z. dawood` in a lowercase mono heading), never
  "Zachariah". He said on 11/16 that the first name is subject to change.
- No emoji, no rounded corners, no blurred shadows, no gradients except the highlighter.
- Copy on the page follows his writing style
  (`~/.claude/projects/-home-zfdawood-work-chr-eyeonit/memory/dawood-writing-style.md`): plain, short,
  spaced hyphens, never em dashes.

## Direction

His own words, 11/16: "a weird mishmash of retro/tui-ish but not overly so, with a warm, archival
vibe, and then also Signalis-esque early 3D aesthetics." Hold all three at once:

- **TUI, turned down.** Mono for structure (headings, labels, readouts), never for reading. Boxes,
  rules and status tags, but no ASCII art, no green-on-black, no fake terminal chrome.
- **Warm archive.** Paper, ink, pencil, a highlighter, ledger tables. Things look filed and
  handled, not printed fresh.
- **Early 3D (PS1, Signalis).** Flat-shaded faces lit from one direction, hard edges, a small
  palette, ordered dithering, low resolution shown at whole-number scale. Light is always from the
  top left, as in cozy-archive.

When a choice could go either way, pick the one a 1998 archive terminal would have made, then
make it legible.

## Adopted from the specimen (11/16)

He chose B, D, E and F, plus focus as an inverted block. All of these are in `brand.css`:
- **The real desk** (B): the desktop's wallpaper (`tools/wallpaper.py` at `[structure] desk_seed`
  and `desk_size`) is generated into `brand.css` as `--desk-img` and drawn at exactly `desk_scale`
  on a fixed `body::before`. To change it, change those tokens and run `make`.
- **The flat-shaded bevel** (D): `.bevel` with eight `<i>` faces, first thing inside `.sheet`.
- **The file header strip** (E): `.readout`, first after the bevel: `archive / agenda / 2026-11-16
  / <b>8 items</b>`, ending in the day/night switch.
- **Bracketed status tags** (F): `.tag` (`.ask`, `.good`, `.parked`), written `[ KEPT ]`.
- **Focus as an inverted block** on chips and buttons only. He did NOT want text selection
  inverted, so selection stays the pink wash.
- **The day/night switch** (asked for 11/16): `theme.js` in `<head>`, plus any
  `<button class="chip" data-theme-toggle>`. Its label comes from CSS and names the mode it
  switches to, and the choice is saved in localStorage.

## Still open

- **Low-poly glyphs** (J): he likes the idea. The first leaf was too simple, so `glyphs/leaf.svg`
  (generated from `[glyph]`) now has 8 faces, dithered half-steps and a pixel stem. Draw new glyphs the same way: faces
  shaded from the top left, ramps from cozy-archive's wallpaper, stems and twigs as pixels.
- **Departure Mono** for 11px labels: not installed. If he adds the .otf, inline it.
- Not chosen: the dithered shadow (C), stepped motion (G), inverted text selection (H), and
  scanlines (I, opt-in at most).

## Used by

All in `~/work/personal`:
- `skills/written-agenda`: meeting agendas (inlines `web/brand.css` through its `render.py`).
- `site/` (zdawood.dev, Elm on Cloudflare Workers, root directory `site`): builds from `web/`.
- `~/brand/specimen.html`: the specimen page (built from `specimen.src.html` here), for trying ideas.

## Feedback log

One dated line per correction. Fold patterns into the rules and tokens above, then into `brand.css`.

- 2026-11-16: first version, from cozy-archive + the wins handout, built for the meeting agendas.
- 2026-11-16: the brand became generated from cozy-archive's tokens.toml (web, Elm, Zed, VS Code,
  QML). Contrast checks found night's `good` (moss on umber, 4.2:1) and moved it to moss_glow.
- 2026-11-16: adopted the real desk, the bevel, the header strip, status tags, inverted focus
  (not selection), and a day/night switch. Footer text sits on a small label so it reads on the wood.
  The leaf glyph was redone (8 faces, dithered, pixel stem). He loves the dark mode.
- 2026-11-16: accents moved from cozy-archive's amber to the handout's purple/pink. Top-level
  headings went to a legible mono (item numbers stay in Kalam). Pages widened to 1200px. Pages are
  local HTML files, not published artifacts.
- 2026-11-17: everything moved into one repo, `zfdawood/personal` (was cozy-archive): the skills,
  the site and the tokens. Generated files are read in place, never copied (`make export` is gone).
