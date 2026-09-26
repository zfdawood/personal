#!/usr/bin/env python3
"""Contrast checker for the Cozy Archive palettes.

Every color a program might render as *text* has to be readable against the
background it will actually sit on. "Readable" is WCAG 2.x relative-luminance
contrast (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio):

    4.5:1  minimum for normal text (AA)
    7.0:1  enhanced (AAA) — used for the main foreground/background pair

Usage:
    tools/contrast.py            check all rules; exit 1 on any failure
    tools/contrast.py --preview  print a truecolor sample of the kitty palette

Stdlib only, so it runs anywhere the repo does.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

REPO = Path(__file__).resolve().parent.parent
KITTY_CONF = REPO / "configs" / "kitty" / "kitty.conf"

AA = 4.5
AAA = 7.0

RGB = tuple[float, float, float]


# ── Color math (pure) ───────────────────────────────────────────────────────

def parse_hex(h: str) -> RGB:
    h = h.lstrip("#")
    if len(h) != 6:
        raise ValueError(f"expected #RRGGBB, got #{h}")
    return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255)


def _linear(c: float) -> float:
    # sRGB transfer function inverse (the threshold is 0.04045 in the sRGB spec;
    # WCAG's 0.03928 differs only for values no 8-bit channel can hit).
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(rgb: RGB) -> float:
    r, g, b = map(_linear, rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    """WCAG contrast ratio, in [1, 21]; symmetric in its arguments."""
    hi, lo = sorted((luminance(parse_hex(a)), luminance(parse_hex(b))), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


# ── Config parsing ──────────────────────────────────────────────────────────

def parse_kitty(text: str) -> dict[str, str]:
    """`key value` lines → {key: value}; later keys win, as in kitty."""
    out: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition(" ")
        out[key] = value.strip()
    return out


# ── Rules ───────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Rule:
    fg: str          # config key rendered as text…
    bg: str          # …on top of this config key
    minimum: float
    why: str


ACCENTS = [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14]

KITTY_RULES: list[Rule] = [
    Rule("foreground", "background", AAA, "body text"),
    Rule("color0", "background", AA, "black text"),
    Rule("color8", "background", AA, "dim text (comments, autosuggestions)"),
    *(Rule(f"color{n}", "background", AA, "ANSI accent as text") for n in ACCENTS),
    # "white" is kept light (ANSI semantics), so it's checked where programs
    # actually put it: on black. Exempt on the parchment background by design.
    Rule("color7", "color0", AA, "white on black (inverse video, TUIs)"),
    Rule("color15", "color0", AA, "bright white on black"),
    Rule("selection_foreground", "selection_background", AA, "selected text"),
    Rule("cursor_text_color", "cursor", AA, "character under the block cursor"),
    Rule("active_tab_foreground", "active_tab_background", AA, "active tab title"),
    Rule("inactive_tab_foreground", "inactive_tab_background", AA, "inactive tab title"),
]


@dataclass(frozen=True)
class Result:
    rule: Rule
    fg_hex: str
    bg_hex: str
    ratio: float

    @property
    def ok(self) -> bool:
        return self.ratio >= self.rule.minimum


def evaluate(rules: list[Rule], colors: Mapping[str, str]) -> list[Result]:
    return [
        Result(r, colors[r.fg], colors[r.bg], contrast(colors[r.fg], colors[r.bg]))
        for r in rules
    ]


# ── Output ──────────────────────────────────────────────────────────────────

def _swatch(fg: str, bg: str, text: str) -> str:
    """Truecolor sample, independent of whatever theme the terminal runs."""
    (fr, fg_, fb), (br, bg_, bb) = (
        tuple(round(c * 255) for c in parse_hex(x)) for x in (fg, bg)
    )
    return f"\033[38;2;{fr};{fg_};{fb};48;2;{br};{bg_};{bb}m{text}\033[0m"


def check() -> int:
    colors = parse_kitty(KITTY_CONF.read_text())
    missing = sorted({k for r in KITTY_RULES for k in (r.fg, r.bg)} - colors.keys())
    if missing:
        print(f"kitty.conf is missing: {', '.join(missing)}", file=sys.stderr)
        return 1

    results = evaluate(KITTY_RULES, colors)
    tty = sys.stdout.isatty()
    print(f"{KITTY_CONF.relative_to(REPO)}")
    for res in results:
        mark = "ok  " if res.ok else "FAIL"
        sample = _swatch(res.fg_hex, res.bg_hex, " Aa ") if tty else ""
        print(
            f"  {mark} {res.ratio:5.2f} ≥ {res.rule.minimum:<3}  "
            f"{res.rule.fg:<24} on {res.rule.bg:<22} {sample} {res.rule.why}"
        )
    failures = [r for r in results if not r.ok]
    print(f"{len(results) - len(failures)}/{len(results)} pass")
    return 1 if failures else 0


def preview() -> int:
    c = parse_kitty(KITTY_CONF.read_text())
    bg = c["background"]
    names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    print(_swatch(c["foreground"], bg, "  default foreground on background  ".ljust(44)))
    for i, name in enumerate(names):
        normal, bright = c[f"color{i}"], c[f"color{i + 8}"]
        print(
            _swatch(normal, bg, f"  {name:<8} {normal}  ")
            + _swatch(bright, bg, f"bright {bright}".ljust(22))
        )
    print(_swatch(c["color7"], c["color0"], "  white on black (inverse video)".ljust(44)))
    print(_swatch(c["selection_foreground"], c["selection_background"], "  selection".ljust(44)))
    print(_swatch(c["cursor_text_color"], c["cursor"], "█ cursor".ljust(44)))
    return 0


if __name__ == "__main__":
    sys.exit(preview() if "--preview" in sys.argv[1:] else check())
