#!/usr/bin/env bash
# Warm Terminal / Cozy Archive — installer
# Copies configs into ~/.config, backing up anything already there.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/configs"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[38;2;201;123;61m::\033[0m %s\n' "$*"; }

# ── Dependency check (informational — won't abort) ──────────────────────────
say "Checking dependencies…"
deps=(Hyprland quickshell kitty mako hyprpaper wofi)
missing=()
for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done
if ((${#missing[@]})); then
    printf '   missing: %s\n' "${missing[*]}"
    printf '   Arch: sudo pacman -S hyprland kitty mako hyprpaper wofi\n'
    printf '         quickshell -> AUR (yay -S quickshell) or quickshell-git\n'
fi

# ── Deploy each config dir, with backup ─────────────────────────────────────
for dir in hypr quickshell kitty mako; do
    target="$DEST/$dir"
    if [[ -e "$target" && ! -L "$target" ]]; then
        say "Backing up existing $target -> $target.bak-$STAMP"
        mv "$target" "$target.bak-$STAMP"
    elif [[ -L "$target" ]]; then
        rm -f "$target"
    fi
    mkdir -p "$DEST"
    say "Installing $dir"
    cp -r "$SRC/$dir" "$target"
done

# ── Fonts: Departure Mono (optional but recommended) ────────────────────────
FONTDIR="$HOME/.local/share/fonts"
QSFONT="$DEST/quickshell/fonts/DepartureMono-Regular.otf"
if [[ ! -f "$QSFONT" ]]; then
    say "Departure Mono not bundled. Fetch it (recommended):"
    printf '   curl -L -o /tmp/dm.zip https://github.com/rektdeckard/departure-mono/releases/latest/download/DepartureMono-1.500.zip\n'
    printf '   unzip -j /tmp/dm.zip "*DepartureMono-Regular.otf" -d "%s"\n' "$FONTDIR"
    printf '   cp "%s/DepartureMono-Regular.otf" "%s"\n' "$FONTDIR" "$(dirname "$QSFONT")"
    printf '   fc-cache -f     # (UI falls back to JetBrains Mono until then)\n'
fi

say "Done. Log into Hyprland (or run 'Hyprland' from a TTY) to see it."
