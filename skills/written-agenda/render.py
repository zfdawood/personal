"""Wrap an agenda body in the brand template.

    python3 -I render.py <body.html> <out.html>

The body file starts with two comment lines, then the markup that goes inside the sheet:

    <!-- title: DevHawk Directions All-Hands -->
    <!-- footer: Built 11/16 from ... -->
    <p class="kicker">...</p>
    ...
"""

import re
import sys
from pathlib import Path

TEMPLATE = Path(__file__).with_name("template.html")
# The look is generated into the repo's web/ (`make` in the repo root), shared with the website.
# resolve(): ~/.claude/skills/written-agenda is a symlink into the repo.
REPO = Path(__file__).resolve().parents[2]
BRAND_CSS = REPO / "web" / "brand.css"
# Agendas don't carry the desk wallpaper: drop its inlined PNGs so the page stays small.
DESK_IMG = re.compile(r'^\s*--desk-img: url\("data:image/png;base64,[^"]*"\);\n', re.M)


def main() -> None:
    body_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    body = body_path.read_text()
    meta = dict(re.findall(r"<!--\s*(title|footer):\s*(.*?)\s*-->", body))
    body = re.sub(r"<!--\s*(title|footer):.*?-->\n?", "", body)
    footer = f"<footer><span>{meta['footer']}</span></footer>" if meta.get("footer") else ""
    page = (
        TEMPLATE.read_text()
        .replace("{{BRAND_CSS}}", DESK_IMG.sub("", BRAND_CSS.read_text()).strip())
        .replace("{{TITLE}}", meta.get("title", "Agenda"))
        .replace("{{BODY}}", body.strip())
        .replace("{{FOOTER}}", footer)
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(page)
    print(out_path)


if __name__ == "__main__":
    main()
