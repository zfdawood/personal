#!/usr/bin/env bash
# Warm Terminal / Cozy Archive — installer
# Copies configs into ~/.config, backing up anything already there, and the
# runtime scripts (apply.py, wallpaper.py) into ~/.local/share/cozy-archive.
#   ./install.sh                full install (backs up existing config dirs)
#   ./install.sh --fonts        fetch the brand's fonts (also part of a full install)
#   ./install.sh --colors-only  redeploy just the generated color files after
#                               editing tokens.toml (no backups: these files are
#                               never hand-edited)
# Your settings (~/.config/cozy-archive/settings.json: keyboard, clock,
# wallpaper seed) are never overwritten; change them from SUPER+comma. `mode`
# is the exception: every install sets it from tokens.toml (see sync_mode).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/configs"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/cozy-archive"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cozy-archive"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[38;2;201;123;61m::\033[0m %s\n' "$*"; }

# The runtime scripts and the tokens the wallpaper is painted from.
install_share() {
    mkdir -p "$SHARE"
    cp "$REPO/tools/apply.py" "$REPO/tools/wallpaper.py" "$REPO/tools/tokens.py" "$REPO/tokens.toml" "$SHARE/"
}

# tokens.toml's `mode` wins on every install: copy it into settings.json so the
# desktop follows the versioned file. The settings menu still flips day/night
# live; the next install puts it back to what tokens.toml says. The other
# settings (keyboard, clock, wallpaper seed) belong to the menu and are kept.
sync_mode() {
    local settings="$DEST/cozy-archive/settings.json"
    [[ -f "$settings" ]] || return 0
    python3 - "$REPO" "$settings" <<'PY'
import json, sys
from pathlib import Path
repo, settings = Path(sys.argv[1]), Path(sys.argv[2])
sys.path.insert(0, str(repo / "tools"))
import tokens
mode = tokens.parse((repo / "tokens.toml").read_text()).mode
s = json.loads(settings.read_text())
if s.get("mode") != mode:
    s["mode"] = mode
    settings.write_text(json.dumps(s, indent=2) + "\n")
    print(f"\033[38;2;201;123;61m::\033[0m Mode set to {mode} (from tokens.toml)")
PY
}

# Link the day/night files for the current settings, draw the wallpaper, and
# (inside a running session) reload kitty, mako and Hyprland. Quickshell
# reloads on its own.
apply_settings() {
    if command -v python3 >/dev/null 2>&1; then
        if pgrep -x Hyprland >/dev/null 2>&1; then python3 "$SHARE/apply.py"
        else python3 "$SHARE/apply.py" --startup; fi
    else
        say "python3 not found: install it (sudo pacman -S python) for the wallpaper and settings menu."
    fi
}

# The brand's faces (tokens.toml [type]), from Google Fonts' GitHub, into
# ~/.local/share/fonts/cozy-archive. Families fontconfig already has are skipped.
install_fonts() {
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/cozy-archive"
    local base="https://raw.githubusercontent.com/google/fonts/main/ofl"
    local -A files=(
        ["JetBrains Mono"]="jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf jetbrainsmono/JetBrainsMono-Italic%5Bwght%5D.ttf"
        ["Newsreader"]="newsreader/Newsreader%5Bopsz,wght%5D.ttf newsreader/Newsreader-Italic%5Bopsz,wght%5D.ttf"
        ["Kalam"]="kalam/Kalam-Regular.ttf kalam/Kalam-Bold.ttf"
        ["Archivo"]="archivo/Archivo%5Bwdth,wght%5D.ttf"
    )
    local family f name fetched=0
    for family in "${!files[@]}"; do
        if fc-list : family | grep -qiF "$family"; then continue; fi
        mkdir -p "$dir"
        for f in ${files[$family]}; do
            name="${f##*/}"; name="${name//%5B/[}"; name="${name//%5D/]}"
            if curl -fsSL -o "$dir/$name.tmp" "$base/$f"; then
                mv "$dir/$name.tmp" "$dir/$name"
            else
                rm -f "$dir/$name.tmp"; say "Couldn't fetch $family ($f): offline? Re-run 'make fonts' later."
                continue 2
            fi
        done
        say "Installed $family"; fetched=1
    done
    if ((fetched)); then fc-cache -f "$dir" >/dev/null; fi
}

if [[ "${1:-}" == "--fonts" ]]; then
    install_fonts
    exit 0
fi

if [[ "${1:-}" == "--colors-only" ]]; then
    while IFS= read -r rel; do
        [[ "$rel" == cozy-archive/* ]] && continue      # settings: never overwrite
        if [[ ! -d "$DEST/$(dirname "$rel")" ]]; then
            say "No $DEST/$(dirname "$rel") — run a full ./install.sh first." >&2
            exit 1
        fi
        cp "$SRC/$rel" "$DEST/$rel"
        say "Updated $rel"
    done < <(python3 "$REPO/tools/gen.py" --list)
    install_share
    rm -rf "$CACHE/wallpapers"        # repaint with the new colors
    sync_mode
    apply_settings
    say "Colors applied."
    exit 0
fi

# ── Dependency check (informational — won't abort) ──────────────────────────
say "Checking dependencies…"
deps=(Hyprland kitty mako python3 nautilus)
missing=()
for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done
# Quickshell ships as `quickshell` and/or `qs` depending on the package.
command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || missing+=(quickshell)
if ((${#missing[@]})); then
    printf '   missing: %s\n' "${missing[*]}"
    printf '   Arch: sudo pacman -S hyprland quickshell kitty mako python nautilus\n'
fi

# ── Deploy each config dir, with backup ─────────────────────────────────────
for dir in hypr quickshell kitty mako; do
    target="$DEST/$dir"
    # Symlinks (e.g. stow-managed dotfiles) are moved aside too, not deleted.
    if [[ -e "$target" || -L "$target" ]]; then
        say "Backing up existing $target -> $target.bak-$STAMP"
        mv "$target" "$target.bak-$STAMP"
    fi
    mkdir -p "$DEST"
    say "Installing $dir"
    cp -r "$SRC/$dir" "$target"
done

# ── Settings: created once, then yours ──────────────────────────────────────
if [[ ! -f "$DEST/cozy-archive/settings.json" ]]; then
    mkdir -p "$DEST/cozy-archive"
    cp "$SRC/cozy-archive/settings.json" "$DEST/cozy-archive/settings.json"
    say "Created $DEST/cozy-archive/settings.json (change it from SUPER+comma)"
fi
install_share
sync_mode

install_fonts

apply_settings
say "Done. Log into Hyprland (or run 'start-hyprland' from a TTY) to see it."
