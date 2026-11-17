"""Presentation aids for agendas: diagrams and screenshots that live in an item's fold-out.

Each function returns an HTML string to paste into an agenda body (inside `<div class="body">`).
Diagrams are inline SVG drawn only with the brand's CSS variables (template.html styles the
`.aid` classes), so they follow dark mode and need no image files. Screenshots are embedded as
data URIs, so the page stays one file.

    import sys; sys.path.insert(0, str(Path.home() / ".claude/skills/written-agenda"))
    import aids
    aids.flow([("customer app", "places the order"), ("driver", "picks up")], "How an order moves")
    aids.bar([("finished unaided", 40, "good"), ("handed to a person", 50, "ask")], "111 builds")
    aids.screenshot(Path("shot.png"), "The customer app's sign-up screen", "Sign up, from the prototype")

Business variant: mono labels, hairline boxes with cut corners, no handwriting, no decoration.
"""

from __future__ import annotations

import base64
import html
from pathlib import Path

W = 960          # every diagram's viewBox width; it scales to the column
CUT = 6          # cut corners, in viewBox units


def _box(x: float, y: float, w: float, h: float, cls: str = "aid-box") -> str:
    c = CUT
    pts = f"{x + c},{y} {x + w - c},{y} {x + w},{y + c} {x + w},{y + h - c} {x + w - c},{y + h} {x + c},{y + h} {x},{y + h - c} {x},{y + c}"
    return f'<polygon class="{cls}" points="{pts}"/>'


def _lines(x: float, y: float, text: str, cls: str, step: float = 17) -> str:
    """Centered text, one tspan per line ('\\n' splits)."""
    spans = "".join(
        f'<tspan x="{x}" dy="{0 if i == 0 else step}">{html.escape(line)}</tspan>'
        for i, line in enumerate(text.split("\n"))
    )
    return f'<text class="{cls}" x="{x}" y="{y}" text-anchor="middle">{spans}</text>'


def _figure(svg: str, caption: str) -> str:
    cap = f"<figcaption>{html.escape(caption)}</figcaption>" if caption else ""
    return f'<figure class="aid">{svg}{cap}</figure>'


def flow(steps: list[tuple[str, str]], caption: str = "", base: str = "") -> str:
    """Boxes left to right with arrows between: (title, detail). `detail` may hold '\\n'.
    `base` draws one wide bar under every step, for what sits beneath all of them."""
    n = len(steps)
    gap = 36
    bw = (W - gap * (n - 1)) / n
    bh = 84
    h = bh + (64 if base else 8)
    parts: list[str] = []
    for i, (title, detail) in enumerate(steps):
        x = i * (bw + gap)
        parts.append(_box(x, 4, bw, bh))
        parts.append(_lines(x + bw / 2, 34, title, "aid-title"))
        parts.append(_lines(x + bw / 2, 58, detail, "aid-detail", 16))
        if i < n - 1:
            ax = x + bw + 6
            parts.append(f'<path class="aid-arrow" d="M{ax},{4 + bh / 2} H{ax + gap - 14}"/>')
            parts.append(f'<path class="aid-head" d="M{ax + gap - 14},{bh / 2 - 1} l8,5 l-8,5 z"/>')
    if base:
        parts.append(_box(0, bh + 22, W, 36, "aid-box aid-base"))
        parts.append(_lines(W / 2, bh + 45, base, "aid-detail"))
    svg = f'<svg viewBox="0 0 {W} {h}" role="img" aria-label="{html.escape(caption or "diagram")}">{"".join(parts)}</svg>'
    return _figure(svg, caption)


def bar(segments: list[tuple[str, float, str]], caption: str = "") -> str:
    """One stacked bar, parts of a whole: (label, value, kind). kind: good | ask | bad | plain.
    Labels sit under their segment (never on the color), each with its value."""
    total = sum(v for _, v, _ in segments)
    parts: list[str] = []
    x = 0.0
    for label, value, kind in segments:
        w = W * value / total
        parts.append(f'<rect class="aid-seg aid-{kind}" x="{x:.1f}" y="4" width="{max(w - 2, 1):.1f}" height="28"/>')
        parts.append(f'<text class="aid-title" x="{x:.1f}" y="54">{value:g}</text>')
        parts.append(f'<text class="aid-detail" x="{x:.1f}" y="72">{html.escape(label)}</text>')
        x += w
    svg = f'<svg viewBox="0 0 {W} 80" role="img" aria-label="{html.escape(caption or "bar")}">{"".join(parts)}</svg>'
    return _figure(svg, caption)


def screenshot(png: Path, alt: str, caption: str = "") -> str:
    """A screenshot as an embedded image. Keep it to what the item is about; crop before embedding."""
    uri = "data:image/png;base64," + base64.b64encode(png.read_bytes()).decode()
    cap = f"<figcaption>{html.escape(caption)}</figcaption>" if caption else ""
    return f'<figure class="aid shot"><img src="{uri}" alt="{html.escape(alt)}" loading="lazy">{cap}</figure>'
