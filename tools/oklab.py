"""sRGB ↔ OKLab, for mixing colors the way the eye steps between them.

Björn Ottosson's matrices (https://bottosson.github.io/posts/oklab/). gen.py mixes
the bevel's faces here, the same way a browser's `color-mix(in oklab, …)` does, so
the web and the desktop can share one computed answer instead of each mixing at
runtime. Stdlib only.
"""

from __future__ import annotations

Lab = tuple[float, float, float]


def _to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _from_linear(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def to_oklab(hex_: str) -> Lab:
    h = hex_.lstrip("#")
    r, g, b = (_to_linear(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720420 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def from_oklab(lab: Lab) -> str:
    L, a, b = lab
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    rgb = (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )
    return "#" + "".join(f"{round(max(0.0, min(1.0, _from_linear(c))) * 255):02X}" for c in rgb)


def mix(a: str, b: str, t: float) -> str:
    """`t` of the way from b to a (t=1 → a), in OKLab: color-mix(in oklab, a t%, b)."""
    la, lb = to_oklab(a), to_oklab(b)
    return from_oklab(tuple(t * x + (1 - t) * y for x, y in zip(la, lb)))
