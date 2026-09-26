#!/usr/bin/env bash
# Warm Terminal / Cozy Archive — installer
# Copies configs into ~/.config, backing up anything already there.
#   ./install.sh                full install (backs up existing config dirs)
#   ./install.sh --colors-only  redeploy just the generated color files, e.g.
#                               after changing `mode` in tokens.toml (no backups:
#                               these files are never hand-edited)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/configs"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[38;2;201;123;61m::\033[0m %s\n' "$*"; }

# Nudge whatever is running to pick up new configs. Quickshell hot-reloads on
# its own; Hyprland watches its main file but not sourced ones.
reload_running() {
    pgrep -x Hyprland >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
    pgrep -x mako >/dev/null 2>&1 && makoctl reload >/dev/null 2>&1 || true
    pgrep -x kitty >/dev/null 2>&1 && pkill -USR1 -x kitty || true   # kitty reloads config on SIGUSR1
}

if [[ "${1:-}" == "--colors-only" ]]; then
    while IFS= read -r rel; do
        if [[ ! -d "$DEST/$(dirname "$rel")" ]]; then
            say "No $DEST/$(dirname "$rel") — run a full ./install.sh first." >&2
            exit 1
        fi
        cp "$SRC/$rel" "$DEST/$rel"
        say "Updated $rel"
    done < <(python3 "$REPO/tools/gen.py" --list)
    reload_running
    say "Colors applied."
    exit 0
fi

# ── Dependency check (informational — won't abort) ──────────────────────────
say "Checking dependencies…"
deps=(Hyprland kitty mako hyprpaper wofi)
missing=()
for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done
# Quickshell ships as `quickshell` and/or `qs` depending on the package.
command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || missing+=(quickshell)
if ((${#missing[@]})); then
    printf '   missing: %s\n' "${missing[*]}"
    printf '   Arch: sudo pacman -S hyprland kitty mako hyprpaper wofi\n'
    printf '         quickshell -> AUR (yay -S quickshell) or quickshell-git\n'
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
    printf '   curl -L -o /tmp/dm.zip https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip\n'
    printf '   mkdir -p "%s" && unzip -j /tmp/dm.zip "*DepartureMono-Regular.otf" -d "%s"\n' "$FONTDIR" "$FONTDIR"
    printf '   fc-cache -f     # (UI falls back to JetBrains Mono until then)\n'
fi

reload_running
say "Done. Log into Hyprland (or run 'Hyprland' from a TTY) to see it."
