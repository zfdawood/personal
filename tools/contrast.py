#!/usr/bin/env python3
"""Contrast checker for the Cozy Archive tokens.

Every color a program might render as *text* has to be readable against the
background it will actually sit on. "Readable" is WCAG 2.x relative-luminance
contrast (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio):

    4.5:1  minimum for normal text (AA)
    7.0:1  enhanced (AAA) — used for the main body-text pairs

Usage:
    tools/contrast.py            check all rules; exit 1 on any failure
    tools/contrast.py --preview  print a truecolor sample of the terminal palette

Stdlib only, so it runs anywhere the repo does.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from typing import Mapping

from tokens import Colors, load

AA = 4.5
AAA = 7.0

RGB = tuple[float, float, float]


# ── Color math (pure) ───────────────────────────────────────────────────────

def parse_hex(h: str) -> RGB:
    h = h.lstrip("#")
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


# ── Rules ───────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Rule:
    fg: str          # token rendered as text…
    bg: str          # …on top of this token
    minimum: float
    why: str


ACCENTS = [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14]

TERMINAL_RULES: list[Rule] = [
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

# Applied to roles.light and roles.dark alike (bar, mako). textTertiary is
# deliberately absent: it only marks inactive UI (empty workspaces), which
# WCAG exempts from contrast requirements.
ROLE_RULES: list[Rule] = [
    Rule("textPrimary", "bgPrimary", AAA, "clock, workspace numbers, notifications"),
    Rule("textSecondary", "bgPrimary", AA, "meter labels, low-urgency notifications"),
    Rule("onAccentSolid", "accentSolid", AA, "active workspace number"),
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


def _report(title: str, rules: list[Rule], colors: Colors, tty: bool) -> list[Result]:
    missing = sorted({k for r in rules for k in (r.fg, r.bg)} - colors.keys())
    if missing:
        raise SystemExit(f"{title}: missing tokens {', '.join(missing)}")
    results = evaluate(rules, colors)
    print(title)
    for res in results:
        mark = "ok  " if res.ok else "FAIL"
        sample = _swatch(res.fg_hex, res.bg_hex, " Aa ") if tty else ""
        print(
            f"  {mark} {res.ratio:5.2f} ≥ {res.rule.minimum:<3}  "
            f"{res.rule.fg:<24} on {res.rule.bg:<22} {sample} {res.rule.why}"
        )
    return results


def check() -> int:
    t = load()
    tty = sys.stdout.isatty()
    results = [
        *_report("terminal", TERMINAL_RULES, t.terminal, tty),
        *(r for mode in ("light", "dark")
          for r in _report(f"roles.{mode}", ROLE_RULES, t.roles[mode], tty)),
    ]
    failures = [r for r in results if not r.ok]
    print(f"{len(results) - len(failures)}/{len(results)} pass")
    return 1 if failures else 0


def preview() -> int:
    c = load().terminal
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
