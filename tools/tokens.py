"""Load and resolve tokens.toml into plain {name: "#RRGGBB"} maps.

Resolution is the only logic here: every non-swatch value is either a swatch
name or a literal hex, and anything else is an error at load time (so a typo
fails `make`, not silently renders the wrong color).
"""

from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

REPO = Path(__file__).resolve().parent.parent
TOKENS = REPO / "tokens.toml"

HEX = re.compile(r"#[0-9A-Fa-f]{6}")

Colors = Mapping[str, str]

MODES = ("light", "dark")


@dataclass(frozen=True)
class Tokens:
    mode: str                         # the active mode: "light" | "dark"
    swatch: Colors
    roles: Mapping[str, Colors]       # mode → role → hex
    terminal: Mapping[str, Colors]    # mode → kitty key → hex
    wallpaper: Mapping[str, Mapping[str, list[str]]]  # mode → material → ramp (hex, dark → light)
    structure: Mapping[str, Any]      # unit, cut, shadow, bevel, page, desk_* (numbers and strings)
    type: Mapping[str, str]           # web font stacks, plus google_fonts (a stylesheet URL)
    web: Mapping[str, Colors]         # mode → brand.css role → hex
    web_alpha: Mapping[str, Mapping[str, tuple[str, float]]]  # mode → role → (hex, alpha)
    editor: Mapping[str, Colors]      # mode → editor UI role → hex
    syntax: Mapping[str, Colors]      # mode → code color → hex
    glyph: Mapping[str, list[str]]    # ramp name → hex list, dark → light


class TokenError(ValueError):
    pass


def _hex(value: Any, where: str) -> str:
    if not isinstance(value, str) or not HEX.fullmatch(value):
        raise TokenError(f"{where}: expected \"#RRGGBB\", got {value!r}")
    return value.upper()


def _resolve(table: Mapping[str, Any], swatch: Colors, where: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for key, ref in table.items():
        loc = f"{where}.{key}"
        if isinstance(ref, str) and ref in swatch:
            out[key] = swatch[ref]
        elif isinstance(ref, str) and ref.startswith("#"):
            out[key] = _hex(ref, loc)
        else:
            raise TokenError(f"{loc}: unknown swatch {ref!r}")
    return out


def _per_mode(raw: Mapping[str, Any], swatch: Colors, section: str) -> dict[str, dict[str, str]]:
    """[section.light] / [section.dark] → resolved maps with identical keys."""
    table = raw.get(section, {})
    if set(table) != set(MODES):
        raise TokenError(f"{section}: expected exactly {' and '.join(MODES)}, got {sorted(table)}")
    out = {mode: _resolve(table[mode], swatch, f"{section}.{mode}") for mode in MODES}
    diff = out["light"].keys() ^ out["dark"].keys()
    if diff:
        raise TokenError(f"{section}: light and dark must define the same keys; differ on {sorted(diff)}")
    return out


def _ramps(raw: Mapping[str, Any], swatch: Colors) -> dict[str, dict[str, list[str]]]:
    """[wallpaper.light] / [wallpaper.dark]: material → list of swatch names."""
    table = raw.get("wallpaper", {})
    if set(table) != set(MODES):
        raise TokenError(f"wallpaper: expected exactly {' and '.join(MODES)}, got {sorted(table)}")
    out: dict[str, dict[str, list[str]]] = {}
    for mode in MODES:
        out[mode] = {}
        for material, names in table[mode].items():
            loc = f"wallpaper.{mode}.{material}"
            if not isinstance(names, list) or not names:
                raise TokenError(f"{loc}: expected a non-empty list of swatch names")
            out[mode][material] = list(_resolve(dict(enumerate(names)), swatch, loc).values())
    if out["light"].keys() != out["dark"].keys():
        raise TokenError("wallpaper: light and dark must define the same materials")
    return out


def _alphas(raw: Mapping[str, Any], swatch: Colors) -> dict[str, dict[str, tuple[str, float]]]:
    """[web_alpha.light] / [web_alpha.dark]: role → [swatch, alpha in (0, 1]]."""
    table = raw.get("web_alpha", {})
    if set(table) != set(MODES):
        raise TokenError(f"web_alpha: expected exactly {' and '.join(MODES)}, got {sorted(table)}")
    out: dict[str, dict[str, tuple[str, float]]] = {}
    for mode in MODES:
        out[mode] = {}
        for key, pair in table[mode].items():
            loc = f"web_alpha.{mode}.{key}"
            ok = (isinstance(pair, list) and len(pair) == 2 and isinstance(pair[1], (int, float))
                  and 0 < pair[1] <= 1)
            if not ok:
                raise TokenError(f"{loc}: expected [swatch, alpha] with 0 < alpha <= 1, got {pair!r}")
            out[mode][key] = (_resolve({key: pair[0]}, swatch, loc)[key], float(pair[1]))
    if out["light"].keys() != out["dark"].keys():
        raise TokenError("web_alpha: light and dark must define the same keys")
    return out


def _glyph(raw: Mapping[str, Any], swatch: Colors) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for name, names in raw.get("glyph", {}).items():
        loc = f"glyph.{name}"
        if not isinstance(names, list) or len(names) < 2:
            raise TokenError(f"{loc}: expected a list of at least two swatch names")
        out[name] = list(_resolve(dict(enumerate(names)), swatch, loc).values())
    return out


STRUCTURE_INTS = ("unit", "cut", "shadow", "bevel", "page", "desk_seed", "desk_scale")
TYPE_KEYS = ("text", "head", "mono", "hand", "google_fonts")


def _structure(raw: Mapping[str, Any]) -> dict[str, Any]:
    table = dict(raw.get("structure", {}))
    for key in STRUCTURE_INTS:
        if not isinstance(table.get(key), int) or table[key] <= 0:
            raise TokenError(f"structure.{key}: expected a positive integer, got {table.get(key)!r}")
    size = table.get("desk_size")
    if not (isinstance(size, str) and re.fullmatch(r"[1-9][0-9]*x[1-9][0-9]*", size)):
        raise TokenError(f"structure.desk_size: expected \"WxH\", got {size!r}")
    return table


def _type(raw: Mapping[str, Any]) -> dict[str, str]:
    table = raw.get("type", {})
    for key in TYPE_KEYS:
        if not isinstance(table.get(key), str) or not table[key]:
            raise TokenError(f"type.{key}: expected a non-empty string")
    return dict(table)


def parse(text: str) -> Tokens:
    raw = tomllib.loads(text)
    mode = raw.get("mode")
    if mode not in MODES:
        raise TokenError(f"mode: expected one of {MODES}, got {mode!r}")
    swatch = {k: _hex(v, f"swatch.{k}") for k, v in raw["swatch"].items()}
    return Tokens(
        mode=mode,
        swatch=swatch,
        roles=_per_mode(raw, swatch, "roles"),
        terminal=_per_mode(raw, swatch, "terminal"),
        wallpaper=_ramps(raw, swatch),
        structure=_structure(raw),
        type=_type(raw),
        web=_per_mode(raw, swatch, "web"),
        web_alpha=_alphas(raw, swatch),
        editor=_per_mode(raw, swatch, "editor"),
        syntax=_per_mode(raw, swatch, "syntax"),
        glyph=_glyph(raw, swatch),
    )


def load(path: Path = TOKENS) -> Tokens:
    return parse(path.read_text())
