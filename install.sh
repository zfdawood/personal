#!/usr/bin/env bash
# Warm Terminal / Cozy Archive — installer
# Copies configs into ~/.config, backing up anything already there, and the
# runtime scripts (apply.py, wallpaper.py) into ~/.local/share/cozy-archive.
#   ./install.sh                full install (backs up existing config dirs)
#   ./install.sh --colors-only  redeploy just the generated color files after
#                               editing tokens.toml (no backups: these files are
#                               never hand-edited)
# Your settings (~/.config/cozy-archive/settings.json: mode, keyboard, clock,
# wallpaper seed) are never overwritten; change them from SUPER+comma.
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
    apply_settings
    say "Colors applied."
    exit 0
fi

# ── Dependency check (informational — won't abort) ──────────────────────────
say "Checking dependencies…"
deps=(Hyprland kitty mako python3)
missing=()
for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done
# Quickshell ships as `quickshell` and/or `qs` depending on the package.
command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || missing+=(quickshell)
if ((${#missing[@]})); then
    printf '   missing: %s\n' "${missing[*]}"
    printf '   Arch: sudo pacman -S hyprland quickshell kitty mako python\n'
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

# ── Fonts: Departure Mono (optional but recommended) ────────────────────────
FONTDIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
SYSFONT="$FONTDIR/DepartureMono-Regular.otf"
QSFONT="$DEST/quickshell/fonts/DepartureMono-Regular.otf"
mkdir -p "$(dirname "$QSFONT")"   # git doesn't track the empty fonts/ dir
if [[ ! -f "$QSFONT" && -f "$SYSFONT" ]]; then
    say "Copying Departure Mono into the Quickshell config"
    cp "$SYSFONT" "$QSFONT"
fi
if [[ ! -f "$QSFONT" ]]; then
    say "Departure Mono not found. Fetch it (recommended), then re-run ./install.sh:"
    printf '   (vm-guest-setup.sh does this for you; the UI falls back to JetBrains Mono)\n'
    printf '   curl -L -o /tmp/dm.zip https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip\n'
    printf '   mkdir -p "%s" && bsdtar -xOf /tmp/dm.zip DepartureMono-1.500/DepartureMono-Regular.otf > "%s/DepartureMono-Regular.otf"\n' "$FONTDIR" "$FONTDIR"
    printf '   fc-cache -f\n'
fi

apply_settings
say "Done. Log into Hyprland (or run 'start-hyprland' from a TTY) to see it."
