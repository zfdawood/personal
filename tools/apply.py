#!/usr/bin/env python3
"""Make the running desktop match ~/.config/cozy-archive/settings.json.

    apply.py             apply and reload running apps (what the settings menu runs)
    apply.py --startup   apply without reloading (Hyprland runs this at login)

install.sh copies this, wallpaper.py, tokens.py and tokens.toml to
~/.local/share/cozy-archive/. Every app ships both day and night colors; this
only switches links and regenerates nothing but the wallpaper:

    mode           kitty/colors.conf → colors-<mode>.conf, mako/config → config-<mode>,
                   hypr/settings.lua (Hyprland picks its colors), wallpaper
    keyboard       hypr/settings.lua (layout + focus keys)
    clock24h       read by Quickshell straight from settings.json
    wallpaperSeed  which vines grow (wallpaper.py)

Wallpapers are cached by (mode, seed, size) under ~/.cache/cozy-archive/, and
the current one's path is written to ~/.cache/cozy-archive/wallpaper, which
Quickshell watches.
"""

from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import wallpaper  # noqa: E402

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "cozy-archive"
SETTINGS = CONFIG / "cozy-archive" / "settings.json"

DEFAULTS = {"mode": "light", "keyboard": "dvorak-native", "clock24h": False, "wallpaperSeed": 1}
KEYBOARDS = ("qwerty", "dvorak", "dvorak-native")

PIXEL = 4          # one wallpaper pixel = one 4px spacing unit on screen


def load_settings() -> dict:
    try:
        s = {**DEFAULTS, **json.loads(SETTINGS.read_text())}
    except (OSError, ValueError):
        s = dict(DEFAULTS)
    if s["mode"] not in wallpaper.MODES:
        s["mode"] = DEFAULTS["mode"]
    if s["keyboard"] not in KEYBOARDS:
        s["keyboard"] = DEFAULTS["keyboard"]
    s["wallpaperSeed"] = int(s["wallpaperSeed"])
    return s


def relink(link: Path, target: str) -> None:
    """Point `link` at `target` (a sibling file name), replacing what's there."""
    tmp = link.with_name(link.name + ".tmp")
    tmp.unlink(missing_ok=True)
    tmp.symlink_to(target)
    tmp.replace(link)


def write_hypr_settings(s: dict) -> None:
    lua = (
        "-- Written by ~/.local/share/cozy-archive/apply.py from settings.json.\n"
        "-- Change these from the settings menu (SUPER+comma), not here.\n"
        f'return {{ mode = "{s["mode"]}", keyboard = "{s["keyboard"]}" }}\n'
    )
    path = CONFIG / "hypr" / "settings.lua"
    if not path.exists() or path.read_text() != lua:
        path.write_text(lua)


def screen_size() -> tuple[int, int]:
    """The largest monitor, in pixels; 1920x1080 if Hyprland isn't reachable."""
    try:
        out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=3).stdout
        mons = json.loads(out)
        w = max(int(m["width"] / m.get("scale", 1)) for m in mons)
        h = max(int(m["height"] / m.get("scale", 1)) for m in mons)
        return w, h
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        return 1920, 1080


def ensure_wallpaper(s: dict) -> Path:
    w, h = screen_size()
    lw, lh = math.ceil(w / PIXEL), math.ceil(h / PIXEL)
    out = CACHE / "wallpapers" / f'{s["mode"]}-{s["wallpaperSeed"]}-{lw}x{lh}.png'
    if not out.exists():
        out.parent.mkdir(parents=True, exist_ok=True)
        tmp = out.with_suffix(".tmp")
        tmp.write_bytes(wallpaper.draw(s["mode"], s["wallpaperSeed"], lw, lh, HERE / "tokens.toml"))
        tmp.replace(out)
    pointer = CACHE / "wallpaper"
    if not pointer.exists() or pointer.read_text() != str(out):
        pointer.write_text(str(out))
    return out


def reload_running() -> None:
    for cmd in (["hyprctl", "reload"], ["makoctl", "reload"], ["pkill", "-USR1", "-x", "kitty"]):
        try:
            subprocess.run(cmd, capture_output=True, timeout=5)
        except (OSError, subprocess.SubprocessError):
            pass


def main(argv: list[str]) -> int:
    s = load_settings()
    mode = s["mode"]
    if (CONFIG / "kitty").is_dir():
        relink(CONFIG / "kitty" / "colors.conf", f"colors-{mode}.conf")
    if (CONFIG / "mako").is_dir():
        relink(CONFIG / "mako" / "config", f"config-{mode}")
    if (CONFIG / "hypr").is_dir():
        write_hypr_settings(s)
    ensure_wallpaper(s)
    if "--startup" not in argv:
        reload_running()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
