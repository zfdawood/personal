#!/usr/bin/env python3
"""Render every app's colors from tokens.toml.

    tools/gen.py           write the generated files under configs/
    tools/gen.py --check   exit 1 if any generated file is out of date

Each renderer is a pure function Tokens → str; the generated files are
committed so install.sh works on a fresh clone without running anything.
"""

from __future__ import annotations

import sys
from pathlib import Path
from string import Template
from typing import Callable, Mapping

from tokens import REPO, Tokens, load

CONFIGS = REPO / "configs"
TEMPLATES = REPO / "templates"

HEADER = "GENERATED from tokens.toml by tools/gen.py — edit tokens.toml, then run `make`."


def kitty(t: Tokens) -> str:
    width = max(map(len, t.terminal))
    body = "\n".join(f"{k.ljust(width)}  {v}" for k, v in t.terminal.items())
    return f"# {HEADER}\n# Included by kitty.conf.\n\n{body}\n"


def hypr(t: Tokens) -> str:
    def argb(hex_: str) -> str:
        return "0xff" + hex_[1:].lower()

    light = t.roles["light"]
    return (
        f"# {HEADER}\n# Sourced by hyprland.conf. Uses roles.light.\n\n"
        f"$accent       = {argb(light['accent'])}\n"
        f"$borderStrong = {argb(light['borderStrong'])}\n"
        f"$bgPrimary    = {argb(light['bgPrimary'])}\n"
    )


def palette_qml(t: Tokens) -> str:
    def obj(colors: Mapping[str, str]) -> str:
        width = max(map(len, colors)) + 1
        rows = ",\n".join(f'        {(k + ":").ljust(width)} "{v}"' for k, v in colors.items())
        return "({\n" + rows + "\n    })"

    return (
        f"// {HEADER}\n"
        "// Theme.qml picks light or dark from here; components read Theme, not this.\n"
        "pragma Singleton\n\n"
        "import QtQuick\n"
        "import Quickshell\n\n"
        "Singleton {\n"
        f"    readonly property var light: {obj(t.roles['light'])}\n"
        f"    readonly property var dark: {obj(t.roles['dark'])}\n"
        "}\n"
    )


def mako(t: Tokens) -> str:
    template = Template((TEMPLATES / "mako.config").read_text())
    return f"# {HEADER}\n# Template: templates/mako.config. Uses roles.light.\n\n" + template.substitute(
        t.roles["light"]
    )


OUTPUTS: dict[Path, Callable[[Tokens], str]] = {
    CONFIGS / "kitty" / "colors.conf": kitty,
    CONFIGS / "hypr" / "colors.conf": hypr,
    CONFIGS / "quickshell" / "Palette.qml": palette_qml,
    CONFIGS / "mako" / "config": mako,
}


def render(t: Tokens) -> dict[Path, str]:
    return {path: fn(t) for path, fn in OUTPUTS.items()}


def main(argv: list[str]) -> int:
    rendered = render(load())
    stale = [p for p, text in rendered.items() if not p.exists() or p.read_text() != text]

    if "--check" in argv:
        for p in stale:
            print(f"out of date: {p.relative_to(REPO)} (run `make`)", file=sys.stderr)
        return 1 if stale else 0

    for p in stale:
        p.write_text(rendered[p])
        print(f"wrote {p.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
