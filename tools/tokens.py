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
    )


def load(path: Path = TOKENS) -> Tokens:
    return parse(path.read_text())
