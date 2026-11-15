#!/usr/bin/env python3
"""Render every app's colors from tokens.toml.

    tools/gen.py           write the generated files under configs/
    tools/gen.py --check   exit 1 if any generated file is out of date
    tools/gen.py --list    print generated paths, relative to configs/

Each renderer is a pure function Tokens → str; the generated files are
committed so install.sh works on a fresh clone without running anything.
"""

from __future__ import annotations

import sys
from pathlib import Path
import json
from functools import partial
from string import Template
from typing import Callable, Mapping

from tokens import MODES, REPO, Tokens, load

CONFIGS = REPO / "configs"
TEMPLATES = REPO / "templates"

HEADER = "GENERATED from tokens.toml by tools/gen.py — edit tokens.toml, then run `make`."


def kitty(t: Tokens, mode: str) -> str:
    colors = t.terminal[mode]
    width = max(map(len, colors))
    body = "\n".join(f"{k.ljust(width)}  {v}" for k, v in colors.items())
    return (
        f"# {HEADER}\n# Uses terminal.{mode}. kitty.conf includes colors.conf, which the\n"
        f"# settings menu (apply.py) links to this file or its other-mode twin.\n\n{body}\n"
    )


def hypr(t: Tokens) -> str:
    names = ("focusBorder", "focusBorderShade", "border", "borderShade", "highlight", "desk", "shadow")
    width = max(map(len, names))

    def table(mode: str) -> str:
        roles = t.roles[mode]
        # Plain colors take 0xAARRGGBB numbers; gradient stops must be strings.
        nums = "\n".join(f"        {n.ljust(width)} = 0xff{roles[n][1:].lower()}," for n in names)
        strs = "\n".join(f'            {n.ljust(width)} = "rgba({roles[n][1:].lower()}ff)",' for n in names)
        return f"    {mode} = {{\n{nums}\n        rgb = {{\n{strs}\n        }},\n    }},"

    body = "\n".join(table(m) for m in MODES)
    return (
        f"-- {HEADER}\n-- Required by hyprland.lua, which picks a mode from settings.lua.\n\n"
        f"return {{\n{body}\n}}\n"
    )


def tokens_qml(t: Tokens) -> str:
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
        f"    // tokens.toml `mode`; Theme.darkMode follows it.\n"
        f"    readonly property bool darkMode: {'true' if t.mode == 'dark' else 'false'}\n"
        f"    readonly property var light: {obj(t.roles['light'])}\n"
        f"    readonly property var dark: {obj(t.roles['dark'])}\n"
        "}\n"
    )


def mako(t: Tokens, mode: str) -> str:
    template = Template((TEMPLATES / "mako.config").read_text())
    return (
        f"# {HEADER}\n# Template: templates/mako.config. Uses roles.{mode}.\n"
        f"# ~/.config/mako/config is a link to this file or its other-mode twin.\n\n"
        + template.substitute(t.roles[mode])
    )


def settings(t: Tokens) -> str:
    """Defaults for a fresh install; install.sh never overwrites an existing one."""
    return json.dumps(
        {"mode": t.mode, "keyboard": "dvorak-native", "clock24h": False, "wallpaperSeed": 1},
        indent=2,
    ) + "\n"


OUTPUTS: dict[Path, Callable[[Tokens], str]] = {
    **{CONFIGS / "kitty" / f"colors-{m}.conf": partial(kitty, mode=m) for m in MODES},
    **{CONFIGS / "mako" / f"config-{m}": partial(mako, mode=m) for m in MODES},
    CONFIGS / "hypr" / "colors.lua": hypr,
    CONFIGS / "quickshell" / "Tokens.qml": tokens_qml,
    CONFIGS / "cozy-archive" / "settings.json": settings,
}


def render(t: Tokens) -> dict[Path, str]:
    return {path: fn(t) for path, fn in OUTPUTS.items()}


def main(argv: list[str]) -> int:
    if "--list" in argv:
        print("\n".join(str(p.relative_to(CONFIGS)) for p in OUTPUTS))
        return 0

    rendered = render(load())
    stale = [p for p, text in rendered.items() if not p.exists() or p.read_text() != text]

    if "--check" in argv:
        for p in stale:
            print(f"out of date: {p.relative_to(REPO)} (run `make`)", file=sys.stderr)
        return 1 if stale else 0

    for p in stale:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(rendered[p])
        print(f"wrote {p.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
