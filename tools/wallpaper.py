#!/usr/bin/env python3
"""Draw the desk wallpaper: low-poly wooden boards with vines growing over them.

    wallpaper.py --mode light --seed 7 --size 320x200 -o out.png

The look is late-90s 3D (PS1-ish): flat-shaded triangles, a small palette,
ordered dithering, and a low resolution that the desktop scales up with hard
pixel edges. Nothing is random at run time: the same (mode, seed, size) always
draws the same picture. A new seed grows a new arrangement of boards and vines.

How it's drawn:
  1. Every pixel gets a *material* (wood, seam, stem, leaf, berry, nail) and a
     continuous *value* in [0, 1] (dark → light).
  2. Shading is one rule for everything: light comes from the top left, the
     same light that casts the desktop's down-right shadows. A flat face is
     lit by how much it faces that light; vines cast a 1px shadow down-right.
  3. Each pixel is dithered (4×4 Bayer matrix) between the two nearest colors
     of ITS material's ramp in tokens.toml, so materials never bleed colors.

Stdlib only (PNG is written with zlib), so it runs anywhere Python does.
"""

from __future__ import annotations

import argparse
import math
import random
import struct
import sys
import zlib
from dataclasses import dataclass, field
from pathlib import Path

from tokens import MODES, load

# Light direction: unit vector pointing TOWARD the light (up-left on screen).
LIGHT = (-1 / math.sqrt(2), -1 / math.sqrt(2))

BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]

MATERIALS = ("wood", "seam", "stem", "leaf", "berry", "nail")


# ── Canvas: material + value per pixel ──────────────────────────────────────

@dataclass
class Canvas:
    w: int
    h: int
    material: list[int] = field(init=False)
    value: list[float] = field(init=False)

    def __post_init__(self) -> None:
        self.material = [0] * (self.w * self.h)
        self.value = [0.5] * (self.w * self.h)

    def put(self, x: int, y: int, mat: str, v: float) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            i = y * self.w + x
            self.material[i] = MATERIALS.index(mat)
            self.value[i] = min(1.0, max(0.0, v))

    def darken(self, x: int, y: int, amount: float) -> None:
        """Shadow: keep the material, lower its value."""
        if 0 <= x < self.w and 0 <= y < self.h:
            i = y * self.w + x
            self.value[i] = max(0.0, self.value[i] - amount)

    def triangle(self, a, b, c, mat: str, v: float) -> None:
        """Fill a triangle (pixel centers inside, edges inclusive)."""
        (x0, y0), (x1, y1), (x2, y2) = a, b, c
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if area == 0:
            return
        for y in range(max(0, math.floor(min(y0, y1, y2))), min(self.h, math.ceil(max(y0, y1, y2)) + 1)):
            for x in range(max(0, math.floor(min(x0, x1, x2))), min(self.w, math.ceil(max(x0, x1, x2)) + 1)):
                px, py = x + 0.5, y + 0.5
                w0 = (x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)
                w1 = (x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)
                w2 = (x0 - px) * (y1 - py) - (x1 - px) * (y0 - py)
                if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
                    self.put(x, y, mat, v)


def facing(nx: float, ny: float) -> float:
    """How much a face with normal (nx, ny) faces the light, mapped to [0, 1]."""
    n = math.hypot(nx, ny) or 1.0
    return ((nx * LIGHT[0] + ny * LIGHT[1]) / n + 1) / 2


def ambient(x: float, y: float, w: int, h: int) -> float:
    """Broad falloff away from the light: brighter top-left, dimmer bottom-right."""
    return 0.10 - 0.22 * ((x / w) + (y / h)) / 2


# ── Boards ──────────────────────────────────────────────────────────────────

def boards(c: Canvas, rng: random.Random) -> None:
    y = -rng.randint(0, 12)
    while y < c.h:
        bh = rng.randint(26, 38)
        base = rng.uniform(0.42, 0.62)
        _board(c, rng, y, bh, base)
        y += bh
    # Seams: a dark 1px gap under each board's top edge is drawn in _board.


def _board(c: Canvas, rng: random.Random, top: int, bh: int, base: float) -> None:
    bot = top + bh
    # Vertical joints where one plank ends and the next begins, staggered.
    joints = [-rng.randint(0, 120)]
    while joints[-1] < c.w:
        joints.append(joints[-1] + rng.randint(110, 220))

    for left, right in zip(joints, joints[1:]):
        plank = base + rng.uniform(-0.06, 0.06)
        # Low-poly strip: points along the top and bottom edges, slightly
        # jittered, then a zig-zag of triangles. Each triangle gets its own
        # flat tone, so the plank reads as faceted, not smooth.
        xs = [left]
        while xs[-1] < right:
            xs.append(min(right, xs[-1] + rng.randint(14, 30)))
        tops = [(x, top + 1 + rng.uniform(0, 1.5)) for x in xs]
        bots = [(x + rng.uniform(-4, 4), bot - rng.uniform(0, 1.5)) for x in xs]
        for i in range(len(xs) - 1):
            for tri in ((tops[i], tops[i + 1], bots[i]), (tops[i + 1], bots[i + 1], bots[i])):
                cx = sum(p[0] for p in tri) / 3
                cy = sum(p[1] for p in tri) / 3
                v = plank + rng.uniform(-0.05, 0.05) + ambient(cx, cy, c.w, c.h)
                c.triangle(*tri, "wood", v)

        # Grain: a few long faint streaks along the plank.
        for _ in range(rng.randint(1, 3)):
            gy = rng.uniform(top + 4, bot - 4)
            phase, amp = rng.uniform(0, 6.28), rng.uniform(0.4, 1.4)
            for x in range(max(0, left), min(c.w, right)):
                yy = int(gy + amp * math.sin(phase + x / rng.uniform(18, 30)))
                if rng.random() < 0.8:
                    c.darken(x, yy, 0.07)

        # Joint line and two nails at each end of the plank.
        if 0 <= right < c.w:
            for jy in range(max(0, top), min(c.h, bot)):
                c.put(right, jy, "seam", 0.0)
        for nx in (left + 4, right - 5):
            for ny in (top + 6, bot - 7):
                if 0 <= nx < c.w and 0 <= ny < c.h:
                    c.put(nx, ny, "nail", 0.85)          # lit head
                    c.put(nx + 1, ny + 1, "nail", 0.15)  # its shadow side
                    c.put(nx + 1, ny, "nail", 0.5)
                    c.put(nx, ny + 1, "nail", 0.5)

    # The gap between this board and the one above: dark, 1px, with the
    # board's top lip catching light just under it.
    for x in range(c.w):
        c.put(x, top, "seam", 0.0)
        if top + 1 < c.h:
            c.value[(top + 1) * c.w + x] = min(1.0, c.value[(top + 1) * c.w + x] + 0.12)


# ── Vines ───────────────────────────────────────────────────────────────────

@dataclass
class Stroke:
    """A vine piece to draw: built first, then drawn shadow-first."""
    kind: str                     # "stem" | "leaf" | "berry"
    pts: list                     # pixels (stem/berry) or triangles (leaf)
    v: list                       # value per pixel / per triangle


def grow(rng: random.Random, x: float, y: float, angle: float, length: int,
         thick: int, w: int, h: int, out: list[Stroke], depth: int = 0) -> None:
    """A random walk with momentum: the heading drifts smoothly, leaves sprout
    on alternating sides, side branches split off, and the tip curls."""
    turn = rng.uniform(-0.04, 0.04)
    side = rng.choice((-1, 1))
    next_leaf = rng.randint(4, 8)
    pixels, values = [], []
    for step in range(length):
        turn = 0.85 * turn + rng.uniform(-0.05, 0.05)
        if step > length - 18:                       # the tip curls into a tendril
            turn += 0.035 * side
        angle += turn
        x += math.cos(angle)
        y += math.sin(angle)
        if not (-10 < x < w + 10 and -10 < y < h + 10):
            break
        t = thick if step < length * 0.6 else 1
        # A stem is a tube: its lit side faces up-left.
        for k in range(t):
            ox, oy = -math.sin(angle) * k, math.cos(angle) * k
            lit = facing(-math.sin(angle) * (1 if k == 0 else -1), math.cos(angle) * (1 if k == 0 else -1))
            pixels.append((int(x + ox), int(y + oy)))
            values.append(0.25 + 0.6 * lit)

        next_leaf -= 1
        if next_leaf <= 0 and step < length - 10:
            out.append(leaf(rng, x, y, angle + side * rng.uniform(0.7, 1.2), rng.uniform(5, 9)))
            side = -side
            next_leaf = rng.randint(5, 10)
        if depth < 2 and step > 20 and rng.random() < 0.012:
            grow(rng, x, y, angle + rng.choice((-1, 1)) * rng.uniform(0.6, 1.1),
                 int((length - step) * rng.uniform(0.4, 0.7)), 1, w, h, out, depth + 1)
        if rng.random() < 0.006:
            out.append(berries(rng, x, y))
    out.append(Stroke("stem", pixels, values))


def leaf(rng: random.Random, x: float, y: float, angle: float, size: float) -> Stroke:
    """A low-poly leaf: a kite split along its midrib into two flat triangles,
    each shaded by which way it faces the light."""
    tip = (x + math.cos(angle) * size, y + math.sin(angle) * size)
    mid = (x + math.cos(angle) * size * 0.45, y + math.sin(angle) * size * 0.45)
    wid = size * rng.uniform(0.32, 0.45)
    nx, ny = -math.sin(angle), math.cos(angle)       # perpendicular to the midrib
    left = (mid[0] + nx * wid, mid[1] + ny * wid)
    right = (mid[0] - nx * wid, mid[1] - ny * wid)
    base = (x, y)
    tris = [(base, left, tip), (base, tip, right)]
    vals = [0.15 + 0.8 * facing(nx, ny), 0.15 + 0.8 * facing(-nx, -ny)]
    return Stroke("leaf", tris, vals)


def berries(rng: random.Random, x: float, y: float) -> Stroke:
    pts, vals = [], []
    for _ in range(rng.randint(2, 4)):
        bx, by = int(x + rng.uniform(-3, 3)), int(y + rng.uniform(1, 5))
        pts += [(bx, by), (bx + 1, by), (bx, by + 1), (bx + 1, by + 1)]
        vals += [0.95, 0.55, 0.55, 0.15]             # lit top-left, shaded bottom-right
    return Stroke("berry", pts, vals)


def vines(c: Canvas, rng: random.Random) -> None:
    strokes: list[Stroke] = []
    # Vines climb in from the edges and corners, leaving the middle calmer.
    starts = [
        (0, rng.uniform(0.1, 0.9) * c.h, rng.uniform(-0.5, 0.5)),            # left edge, rightward
        (rng.uniform(0.05, 0.6) * c.w, 0, math.pi / 2 + rng.uniform(-0.5, 0.5)),  # top edge, downward
        (c.w, rng.uniform(0.5, 1.0) * c.h, math.pi + rng.uniform(-0.6, 0.2)),     # right edge, leftward
        (rng.uniform(0.3, 1.0) * c.w, c.h, -math.pi / 2 + rng.uniform(-0.5, 0.5)),  # bottom, upward
    ]
    for _ in range(rng.randint(0, 2)):
        starts.append(rng.choice(starts))
    for x, y, a in starts:
        grow(rng, x, y, a, rng.randint(int(c.w * 0.35), int(c.w * 0.7)), 2, c.w, c.h, strokes)

    # Shadows first (1px down-right, like every shadow on the desktop), then
    # the vines over them.
    for s in strokes:
        if s.kind == "leaf":
            for tri in s.pts:
                shifted = [(px + 1, py + 1) for px, py in tri]
                _shadow_triangle(c, shifted)
        else:
            for px, py in s.pts:
                c.darken(px + 1, py + 1, 0.28)
    for s in strokes:
        if s.kind == "leaf":
            for tri, v in zip(s.pts, s.v):
                c.triangle(*tri, "leaf", v)
        else:
            for (px, py), v in zip(s.pts, s.v):
                c.put(px, py, s.kind, v)


def _shadow_triangle(c: Canvas, tri) -> None:
    # Rasterize into a scratch canvas-free mask by reusing triangle() logic.
    (x0, y0), (x1, y1), (x2, y2) = tri
    for y in range(max(0, math.floor(min(y0, y1, y2))), min(c.h, math.ceil(max(y0, y1, y2)) + 1)):
        for x in range(max(0, math.floor(min(x0, x1, x2))), min(c.w, math.ceil(max(x0, x1, x2)) + 1)):
            px, py = x + 0.5, y + 0.5
            w0 = (x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)
            w1 = (x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)
            w2 = (x0 - px) * (y1 - py) - (x1 - px) * (y0 - py)
            if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
                c.darken(x, y, 0.22)


# ── Dither to the palette, write PNG ────────────────────────────────────────

def _rgb(h: str) -> tuple[int, int, int]:
    return int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)


def _to_linear(c: int) -> float:
    s = c / 255
    return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4


def _from_linear(v: float) -> int:
    s = 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return round(max(0.0, min(1.0, s)) * 255)


def refine(ramp: list[tuple[int, int, int]], steps: int) -> list[tuple[int, int, int]]:
    """Insert `steps - 1` colors between each pair of ramp colors, mixed in
    linear light (how light actually adds up), so dithering only ever has to
    bridge a small gap. The named swatches stay exactly as they are."""
    if len(ramp) < 2 or steps < 2:
        return ramp
    out = []
    for a, b in zip(ramp, ramp[1:]):
        la, lb = [_to_linear(x) for x in a], [_to_linear(x) for x in b]
        for k in range(steps):
            t = k / steps
            out.append(tuple(_from_linear(p + (q - p) * t) for p, q in zip(la, lb)))
    return out + [ramp[-1]]


# Between two named swatches, how many steps the dithering works across.
# 1 = the raw palette (harsh, NES-like); 3 = PS1-ish: dither visible up close.
REFINE = 3


def render(c: Canvas, ramps: dict[str, list[str]]) -> bytes:
    """Ordered dithering within each material's ramp: a value between two ramp
    steps becomes a Bayer pattern of those two colors."""
    rgb = {MATERIALS.index(m): refine([_rgb(h) for h in ramps[m]], REFINE) for m in MATERIALS}
    rows = []
    for y in range(c.h):
        row = bytearray([0])                          # PNG filter: none
        for x in range(c.w):
            i = y * c.w + x
            ramp = rgb[c.material[i]]
            pos = c.value[i] * (len(ramp) - 1)
            lo = int(pos)
            frac = pos - lo
            threshold = (BAYER4[y % 4][x % 4] + 0.5) / 16
            idx = min(len(ramp) - 1, lo + (1 if frac > threshold else 0))
            row += bytes(ramp[idx])
        rows.append(bytes(row))
    return png(c.w, c.h, b"".join(rows))


def png(w: int, h: int, raw: bytes) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)   # 8-bit RGB
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def draw(mode: str, seed: int, w: int, h: int, tokens_path: Path | None = None) -> bytes:
    t = load(tokens_path) if tokens_path else load()
    rng = random.Random(f"{seed}")                     # same seed → same boards and vines, any mode
    c = Canvas(w, h)
    boards(c, rng)
    vines(c, rng)
    return render(c, t.wallpaper[mode])


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--mode", choices=MODES, default="light")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--size", default="320x200", help="low-res size, WxH (shown scaled up)")
    ap.add_argument("--tokens", type=Path, help="tokens.toml to read (default: the repo's)")
    ap.add_argument("-o", "--out", type=Path, required=True)
    a = ap.parse_args(argv)
    w, h = (int(n) for n in a.size.lower().split("x"))
    a.out.write_bytes(draw(a.mode, a.seed, w, h, a.tokens))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
