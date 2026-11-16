"""Renderers for everything outside the desktop that wears the brand.

    web/brand.css         custom properties for both modes + templates/web/components.css
    web/theme.js          the day/night switch (templates/web/theme.js, stamped)
    web/glyphs/leaf.svg   the low-poly leaf
    web/Brand.elm         the web palette and the leaf, for Elm sites
    editors/zed/…         a Zed theme family (Day, Night)
    editors/vscode/…      a VS Code theme extension (Day, Night)

Every function here is pure: Tokens → str, the same bytes for the same tokens.
Things that are rules rather than values are computed here once, so every output
gets the identical answer: the bevel's face colors (Card.qml's Lambert rule), the
leaf's dithered faces, and the desk (wallpaper.py, by seed).
"""

from __future__ import annotations

import base64
import json
import math
import re
from typing import Mapping

import oklab
import wallpaper
from tokens import MODES, REPO, Tokens

TEMPLATES = REPO / "templates"
HEADER = "GENERATED from tokens.toml by tools/gen.py. Edit tokens.toml (or templates/web/), then run `make`."
LIGHT = (-math.sqrt(0.5), -math.sqrt(0.5))   # toward the light: up-left on screen


# ── Rules computed once ─────────────────────────────────────────────────────

# The bevel's eight faces, top first, clockwise, as outward normals (Card.qml's order).
FACE_NORMALS = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]


def facing(nx: float, ny: float) -> float:
    """How directly a face looks at the light: Lambert's cosine mapped to [0, 1]."""
    n = math.hypot(nx, ny)
    return ((nx * LIGHT[0] + ny * LIGHT[1]) / n + 1) / 2


def bevel_faces(lit: str, shade: str) -> list[str]:
    return [oklab.mix(lit, shade, facing(nx, ny)) for nx, ny in FACE_NORMALS]


def desk_png(t: Tokens, mode: str) -> bytes:
    w, h = (int(n) for n in t.structure["desk_size"].split("x"))
    return wallpaper.draw(mode, t.structure["desk_seed"], w, h)


# The leaf: a 32×20 model, one unit = one brand unit. Faces either side of a curved
# midrib carry a light value in [0, 1] (upper half lit, both halves darkening toward
# the stem); the stem is pixels, a 2-unit staircase, lit on top and shaded below.
LEAF_FACES: list[tuple[str, float]] = [
    ("2,10 8,5 8,10.5", 1.0),
    ("8,5 15,3 15,10 8,10.5", 0.875),
    ("15,3 22,6 22,9.5 15,10", 0.75),
    ("22,6 26,10 22,9.5", 0.625),
    ("2,10 8,10.5 8,14", 0.5),
    ("8,10.5 15,10 15,16 8,14", 0.375),
    ("15,10 22,9.5 22,14 15,16", 0.25),
    ("22,9.5 26,10 22,14", 0.125),
]
LEAF_STEM: list[tuple[int, int, int, float]] = [   # x, y, width, light
    (25, 9, 2, 1.0), (25, 10, 2, 0.0),
    (27, 10, 2, 1.0), (27, 11, 2, 0.0),
    (29, 11, 1, 1.0), (29, 12, 1, 0.0),
    (30, 12, 1, 0.5), (30, 13, 1, 0.0),
    (31, 13, 1, 0.5), (31, 14, 1, 0.0),
]


def shade(value: float, ramp: list[str]) -> tuple[str, str | None]:
    """A light value → a ramp color, or a 2×2 dither of the two nearest when it falls
    halfway between steps (the wallpaper's trick for more shades from a small palette)."""
    p = value * (len(ramp) - 1)
    lo = math.floor(p + 1e-9)
    frac = p - lo
    if abs(frac - 0.5) < 1e-9:
        return ramp[lo + 1], ramp[lo]
    return ramp[min(len(ramp) - 1, round(p))], None


def _pattern_id(base: str, other: str) -> str:
    return f"leaf-{base[1:].lower()}-{other[1:].lower()}"


def leaf_model(t: Tokens) -> tuple[list[tuple[str, str, str]], list[tuple[int, int, int, str]], list[tuple[str, str]]]:
    """(patterns as (id, base, other), stem pixels as (x, y, w, color), faces as (points, fill))."""
    patterns: dict[str, tuple[str, str]] = {}
    faces: list[tuple[str, str]] = []
    for points, value in LEAF_FACES:
        base, other = shade(value, t.glyph["leaf"])
        if other is None:
            faces.append((points, base))
        else:
            pid = _pattern_id(base, other)
            patterns.setdefault(pid, (base, other))
            faces.append((points, f"url(#{pid})"))
    stem = [(x, y, w, shade(v, t.glyph["stem"])[0]) for x, y, w, v in LEAF_STEM]
    return [(pid, b, o) for pid, (b, o) in patterns.items()], stem, faces


# ── Web ─────────────────────────────────────────────────────────────────────

def _kebab(name: str) -> str:
    return re.sub(r"(?<!^)([A-Z])", r"-\1", name).lower()


def _rgba(hex_: str, alpha: float) -> str:
    r, g, b = (int(hex_[i:i + 2], 16) for i in (1, 3, 5))
    return f"rgb({r} {g} {b} / {alpha:g})"


def _color_block(t: Tokens, mode: str, indent: str) -> str:
    web = t.web[mode]
    lines = [f"--{_kebab(k)}: {v};" for k, v in web.items()]
    lines += [f"--{_kebab(k)}: {_rgba(h, a)};" for k, (h, a) in t.web_alpha[mode].items()]
    lines += [f"--bevel-{i}: {c};" for i, c in enumerate(bevel_faces(web["lit"], web["ruleShade"]), 1)]
    uri = "data:image/png;base64," + base64.b64encode(desk_png(t, mode)).decode()
    lines.append(f'--desk-img: url("{uri}");')
    return "\n".join(indent + line for line in lines)


def brand_css(t: Tokens) -> str:
    s, ty = t.structure, t.type
    w, h = (int(n) * s["desk_scale"] for n in s["desk_size"].split("x"))
    structure = "\n".join(f"  {line}" for line in [
        f"--u: {s['unit']}px;",
        f"--cut: calc({s['cut']} * var(--u));",
        f"--shadow-offset: calc({s['shadow']} * var(--u));",
        f"--bevel: {s['bevel']}px;",
        f"--page: {s['page']}px;",
        f"--desk-size: {w}px {h}px;   /* the desk at exactly {s['desk_scale']}x */",
        *(f"--{k}: {ty[k]};" for k in ("text", "head", "mono", "hand")),
    ])
    dark = _color_block(t, "dark", "    ")
    return (
        f"/* {HEADER}\n   Fonts: {ty['google_fonts']} */\n"
        f":root {{\n{structure}\n  /* day: parchment on oak */\n{_color_block(t, 'light', '  ')}\n}}\n"
        f"@media (prefers-color-scheme: dark) {{\n  :root:not([data-theme=\"light\"]) {{\n{dark}\n    color-scheme: dark;\n  }}\n}}\n"
        f":root[data-theme=\"dark\"] {{\n{_color_block(t, 'dark', '  ')}\n  color-scheme: dark;\n}}\n\n"
        + (TEMPLATES / "web" / "components.css").read_text()
    )


def theme_js(t: Tokens) -> str:
    return f"// {HEADER}\n" + (TEMPLATES / "web" / "theme.js").read_text()


def leaf_svg(t: Tokens) -> str:
    patterns, stem, faces = leaf_model(t)
    defs = "\n".join(
        f'    <pattern id="{pid}" width="2" height="2" patternUnits="userSpaceOnUse">'
        f'<rect width="2" height="2" fill="{b}"/><rect width="1" height="1" fill="{o}"/>'
        f'<rect x="1" y="1" width="1" height="1" fill="{o}"/></pattern>'
        for pid, b, o in patterns
    )
    pixels = "\n".join(f'    <rect x="{x}" y="{y}" width="{w}" height="1" fill="{c}"/>' for x, y, w, c in stem)
    polys = "\n".join(f'  <polygon points="{p}" fill="{f}"/>' for p, f in faces)
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" class="glyph" viewBox="0 0 32 20" shape-rendering="crispEdges" '
        'role="img" aria-label="A low-poly leaf">\n'
        f"  <!-- {HEADER}\n       One viewBox unit is one brand unit: show it 32 by 20 units. -->\n"
        f"  <defs>\n{defs}\n  </defs>\n  <g>\n{pixels}\n  </g>\n{polys}\n</svg>\n"
    )


def brand_elm(t: Tokens) -> str:
    keys = list(t.web["light"])
    field_types = "\n    , ".join(f"{k} : String" for k in keys)

    def record(mode: str) -> str:
        return "\n            , ".join(f'{k} = "{t.web[mode][k]}"' for k in keys)

    patterns, stem, faces = leaf_model(t)

    def pattern(pid: str, b: str, o: str) -> str:
        return (
            f'Svg.pattern [ SA.id "{pid}", SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]\n'
            f'                [ Svg.rect [ SA.width "2", SA.height "2", SA.fill "{b}" ] []\n'
            f'                , Svg.rect [ SA.width "1", SA.height "1", SA.fill "{o}" ] []\n'
            f'                , Svg.rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill "{o}" ] []\n'
            f"                ]"
        )

    children = (
        ["Svg.defs []\n            [ " + "\n            , ".join(pattern(*p) for p in patterns) + "\n            ]"]
        + [f'Svg.rect [ SA.x "{x}", SA.y "{y}", SA.width "{w}", SA.height "1", SA.fill "{c}" ] []' for x, y, w, c in stem]
        + [f'Svg.polygon [ SA.points "{p}", SA.fill "{f}" ] []' for p, f in faces]
    )
    return f'''module Brand exposing (Mode(..), Palette, leaf, palette)

{{-| {HEADER}

The web palette for both modes, and the low-poly leaf, so an Elm site never hardcodes a color.

-}}

import Html.Attributes
import Svg exposing (Svg)
import Svg.Attributes as SA


type Mode
    = Day
    | Night


type alias Palette =
    {{ {field_types}
    }}


palette : Mode -> Palette
palette mode =
    case mode of
        Day ->
            {{ {record("light")}
            }}

        Night ->
            {{ {record("dark")}
            }}


{{-| The low-poly leaf: one viewBox unit is one brand unit. Style it with `svg.glyph`.
-}}
leaf : Svg msg
leaf =
    Svg.svg
        [ SA.class "glyph"
        , SA.viewBox "0 0 32 20"
        , SA.shapeRendering "crispEdges"
        , Html.Attributes.attribute "role" "img"
        , Html.Attributes.attribute "aria-label" "A low-poly leaf"
        ]
        [ {"\n        , ".join(children)}
        ]
'''


# ── Editors ─────────────────────────────────────────────────────────────────

ANSI = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]


def _zed_theme(t: Tokens, mode: str) -> dict:
    e, sx, term = t.editor[mode], t.syntax[mode], t.terminal[mode]
    style: dict[str, object] = {
        "background": e["surface"],
        "surface.background": e["surface"],
        "elevated_surface.background": e["background"],
        "panel.background": e["surface"],
        "panel.focused_border": e["accent"],
        "pane.focused_border": e["accent"],
        "border": e["border"],
        "border.variant": e["border"],
        "border.focused": e["accent"],
        "border.selected": e["accentSolid"],
        "border.transparent": "#00000000",
        "border.disabled": e["border"],
        "element.background": e["surface"],
        "element.hover": e["selection"],
        "element.active": e["selection"],
        "element.selected": e["selection"],
        "element.disabled": e["surface"],
        "ghost_element.background": "#00000000",
        "ghost_element.hover": e["selection"],
        "ghost_element.active": e["selection"],
        "ghost_element.selected": e["selection"],
        "drop_target.background": e["selection"] + "80",
        "text": e["text"],
        "text.muted": e["textMuted"],
        "text.placeholder": e["textFaint"],
        "text.disabled": e["textFaint"],
        "text.accent": e["accentSolid"],
        "icon": e["textMuted"],
        "icon.muted": e["textFaint"],
        "icon.accent": e["accentSolid"],
        "title_bar.background": e["chrome"],
        "status_bar.background": e["chrome"],
        "toolbar.background": e["background"],
        "tab_bar.background": e["surface"],
        "tab.inactive_background": e["surface"],
        "tab.active_background": e["background"],
        "search.match_background": t.web_alpha[mode]["hl"][0] + "55",
        "scrollbar.thumb.background": e["border"] + "AA",
        "scrollbar.thumb.hover_background": e["textFaint"] + "AA",
        "scrollbar.track.background": "#00000000",
        "editor.background": e["background"],
        "editor.foreground": e["text"],
        "editor.gutter.background": e["background"],
        "editor.subheader.background": e["surface"],
        "editor.active_line.background": e["lineHighlight"],
        "editor.highlighted_line.background": e["lineHighlight"],
        "editor.line_number": e["textFaint"],
        "editor.active_line_number": e["text"],
        "editor.invisible": e["border"],
        "editor.wrap_guide": e["border"],
        "editor.active_wrap_guide": e["textFaint"],
        "editor.indent_guide": e["border"],
        "editor.indent_guide_active": e["textFaint"],
        "editor.document_highlight.read_background": e["selection"] + "80",
        "editor.document_highlight.write_background": e["selection"],
        "link_text.hover": e["accent"],
        "error": e["error"],
        "warning": e["warning"],
        "success": e["success"],
        "info": e["info"],
        "hint": e["textFaint"],
        "created": e["success"],
        "modified": e["warning"],
        "deleted": e["error"],
        "conflict": e["error"],
        "terminal.background": term["background"],
        "terminal.foreground": term["foreground"],
        "terminal.bright_foreground": term["foreground"],
        "terminal.dim_foreground": term["color8"],
    }
    for i, name in enumerate(ANSI):
        style[f"terminal.ansi.{name}"] = term[f"color{i}"]
        style[f"terminal.ansi.bright_{name}"] = term[f"color{i + 8}"]
    style["players"] = [{"cursor": e["cursor"], "background": e["cursor"], "selection": e["selection"] + "CC"}]
    mapping = {
        "comment": ("comment", "italic"), "comment.doc": ("comment", "italic"),
        "keyword": ("keyword", None), "preproc": ("keyword", None),
        "string": ("string", None), "string.escape": ("constant", None), "string.regex": ("string", None),
        "string.special": ("string", None), "string.special.symbol": ("constant", None),
        "number": ("number", None), "boolean": ("constant", None), "constant": ("constant", None),
        "function": ("function", None), "constructor": ("type", None),
        "type": ("type", None), "enum": ("type", None), "variant": ("constant", None),
        "tag": ("tag", None), "attribute": ("attribute", None), "property": ("property", None),
        "label": ("attribute", None),
        "variable": ("variable", None), "variable.special": ("keyword", "italic"),
        "operator": ("operator", None), "punctuation": ("punctuation", None),
        "punctuation.bracket": ("punctuation", None), "punctuation.delimiter": ("punctuation", None),
        "punctuation.list_marker": ("keyword", None), "punctuation.special": ("keyword", None),
        "title": ("keyword", None), "emphasis": ("variable", "italic"), "emphasis.strong": ("variable", None),
        "link_text": ("function", None), "link_uri": ("string", None), "text.literal": ("string", None),
    }
    syntax = {}
    for scope, (role, font_style) in mapping.items():
        entry: dict[str, object] = {"color": sx[role]}
        if font_style:
            entry["font_style"] = font_style
        if scope == "emphasis.strong":
            entry["font_weight"] = 700
        syntax[scope] = entry
    style["syntax"] = syntax
    return {
        "name": f"Cozy Archive {'Day' if mode == 'light' else 'Night'}",
        "appearance": mode,
        "style": style,
    }


def zed(t: Tokens) -> str:
    doc = {
        "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
        "name": "Cozy Archive",
        "author": "Z. Dawood",
        "themes": [_zed_theme(t, m) for m in MODES],
    }
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def vscode_package(t: Tokens) -> str:
    doc = {
        "name": "cozy-archive-theme",
        "displayName": "Cozy Archive",
        "description": f"Parchment on an oak desk, lit from the top left. {HEADER}",
        "version": "0.1.0",
        "publisher": "zdawood",
        "engines": {"vscode": "^1.80.0"},
        "categories": ["Themes"],
        "contributes": {
            "themes": [
                {"label": "Cozy Archive Day", "uiTheme": "vs", "path": "./themes/cozy-archive-day.json"},
                {"label": "Cozy Archive Night", "uiTheme": "vs-dark", "path": "./themes/cozy-archive-night.json"},
            ]
        },
    }
    return json.dumps(doc, indent=2) + "\n"


def vscode_theme(t: Tokens, mode: str) -> str:
    e, sx, term = t.editor[mode], t.syntax[mode], t.terminal[mode]
    colors: dict[str, str] = {
        "focusBorder": e["accent"],
        "foreground": e["text"],
        "descriptionForeground": e["textMuted"],
        "errorForeground": e["error"],
        "textLink.foreground": e["accentSolid"],
        "textLink.activeForeground": e["accent"],
        "editor.background": e["background"],
        "editor.foreground": e["text"],
        "editorLineNumber.foreground": e["textFaint"],
        "editorLineNumber.activeForeground": e["text"],
        "editorCursor.foreground": e["cursor"],
        "editor.selectionBackground": e["selection"],
        "editor.inactiveSelectionBackground": e["selection"] + "99",
        "editor.lineHighlightBackground": e["lineHighlight"],
        "editor.findMatchHighlightBackground": t.web_alpha[mode]["hl"][0] + "55",
        "editorIndentGuide.background1": e["border"],
        "editorIndentGuide.activeBackground1": e["textFaint"],
        "editorWhitespace.foreground": e["border"],
        "editorRuler.foreground": e["border"],
        "editorGutter.background": e["background"],
        "editorError.foreground": e["error"],
        "editorWarning.foreground": e["warning"],
        "editorInfo.foreground": e["info"],
        "editorWidget.background": e["surface"],
        "editorWidget.border": e["border"],
        "editorGroup.border": e["border"],
        "editorGroupHeader.tabsBackground": e["surface"],
        "tab.activeBackground": e["background"],
        "tab.activeForeground": e["text"],
        "tab.activeBorderTop": e["accentSolid"],
        "tab.inactiveBackground": e["surface"],
        "tab.inactiveForeground": e["textMuted"],
        "tab.border": e["border"],
        "sideBar.background": e["surface"],
        "sideBar.foreground": e["text"],
        "sideBar.border": e["border"],
        "sideBarSectionHeader.background": e["surface"],
        "activityBar.background": e["chrome"],
        "activityBar.foreground": e["text"],
        "activityBar.inactiveForeground": e["textFaint"],
        "activityBarBadge.background": e["accentSolid"],
        "activityBarBadge.foreground": e["onAccentSolid"],
        "titleBar.activeBackground": e["chrome"],
        "titleBar.activeForeground": e["text"],
        "titleBar.inactiveBackground": e["chrome"],
        "titleBar.inactiveForeground": e["textMuted"],
        "statusBar.background": e["chrome"],
        "statusBar.foreground": e["text"],
        "statusBar.border": e["border"],
        "panel.background": e["surface"],
        "panel.border": e["border"],
        "panelTitle.activeForeground": e["text"],
        "panelTitle.activeBorder": e["accentSolid"],
        "list.activeSelectionBackground": e["selection"],
        "list.activeSelectionForeground": e["text"],
        "list.inactiveSelectionBackground": e["selection"],
        "list.hoverBackground": e["lineHighlight"],
        "list.focusOutline": e["accent"],
        "input.background": e["background"],
        "input.foreground": e["text"],
        "input.border": e["border"],
        "input.placeholderForeground": e["textFaint"],
        "button.background": e["accentSolid"],
        "button.foreground": e["onAccentSolid"],
        "badge.background": e["accentSolid"],
        "badge.foreground": e["onAccentSolid"],
        "scrollbarSlider.background": e["border"] + "99",
        "scrollbarSlider.hoverBackground": e["textFaint"] + "99",
        "terminal.background": term["background"],
        "terminal.foreground": term["foreground"],
        "terminalCursor.foreground": term["cursor"],
        "terminal.selectionBackground": term["selection_background"],
    }
    for i, name in enumerate(ANSI):
        cap = name.capitalize()
        colors[f"terminal.ansi{cap}"] = term[f"color{i}"]
        colors[f"terminal.ansiBright{cap}"] = term[f"color{i + 8}"]

    def rule(name: str, scopes: list[str], role: str, font_style: str | None = None) -> dict:
        settings: dict[str, str] = {"foreground": sx[role]}
        if font_style:
            settings["fontStyle"] = font_style
        return {"name": name, "scope": scopes, "settings": settings}

    token_colors = [
        rule("Comments", ["comment", "punctuation.definition.comment"], "comment", "italic"),
        rule("Keywords", ["keyword", "storage.type", "storage.modifier", "keyword.control"], "keyword"),
        rule("Strings", ["string", "string.quoted", "markup.inline.raw"], "string"),
        rule("Numbers", ["constant.numeric"], "number"),
        rule("Constants", ["constant.language", "constant.character", "support.constant", "variable.other.constant"], "constant"),
        rule("Functions", ["entity.name.function", "support.function", "meta.function-call"], "function"),
        rule("Types", ["entity.name.type", "entity.name.class", "support.type", "support.class", "entity.other.inherited-class"], "type"),
        rule("Tags", ["entity.name.tag"], "tag"),
        rule("Attributes", ["entity.other.attribute-name"], "attribute"),
        rule("Properties", ["variable.other.property", "support.variable.property", "meta.object-literal.key"], "property"),
        rule("Variables", ["variable", "variable.parameter"], "variable"),
        rule("Operators", ["keyword.operator"], "operator"),
        rule("Punctuation", ["punctuation", "meta.brace"], "punctuation"),
        rule("Headings", ["markup.heading", "entity.name.section"], "keyword"),
        rule("Emphasis", ["markup.italic"], "variable", "italic"),
        rule("Strong", ["markup.bold"], "variable", "bold"),
        rule("Links", ["markup.underline.link"], "function"),
    ]
    doc = {
        "$comment": HEADER,
        "name": f"Cozy Archive {'Day' if mode == 'light' else 'Night'}",
        "type": "light" if mode == "light" else "dark",
        "semanticHighlighting": True,
        "colors": colors,
        "tokenColors": token_colors,
    }
    return json.dumps(doc, indent=2) + "\n"
