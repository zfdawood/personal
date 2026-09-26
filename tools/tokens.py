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


@dataclass(frozen=True)
class Tokens:
    swatch: Colors
    roles: Mapping[str, Colors]   # mode ("light" | "dark") → role → hex
    terminal: Colors


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


def parse(text: str) -> Tokens:
    raw = tomllib.loads(text)
    swatch = {k: _hex(v, f"swatch.{k}") for k, v in raw["swatch"].items()}
    roles = {
        mode: _resolve(table, swatch, f"roles.{mode}")
        for mode, table in raw["roles"].items()
    }
    if roles.keys() != {"light", "dark"}:
        raise TokenError(f"roles: expected light and dark, got {sorted(roles)}")
    if roles["light"].keys() != roles["dark"].keys():
        diff = roles["light"].keys() ^ roles["dark"].keys()
        raise TokenError(f"roles: light and dark must define the same roles; differ on {sorted(diff)}")
    return Tokens(swatch, roles, _resolve(raw["terminal"], swatch, "terminal"))


def load(path: Path = TOKENS) -> Tokens:
    return parse(path.read_text())
