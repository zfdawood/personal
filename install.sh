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
    # Where tokens.toml lives, for the settings menu's color picker, which edits
    # it in place (tools/palette.py) rather than a copy.
    printf '%s\n' "$REPO" > "$SHARE/repo"
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

# The boot greeter (configs/quickshell/greeter.qml): the lock screen's login
# card, shown by greetd before anyone is logged in. Needs sudo, because the
# greeter runs as greetd's `greeter` user and can't read your home:
#   /usr/share/cozy-archive/quickshell/   the shell (greeter.qml + the shared cards),
#                                         greeter.json (you, start-hyprland) and its desk
#   /usr/local/share/fonts/cozy-archive/  the brand's fonts
#   /etc/greetd/cozy-archive.lua          a bare Hyprland that runs the greeter
#   /etc/greetd/config.toml               points greetd at it (the old one is kept as .bak-<stamp>)
# Re-run after changing tokens or the cards. It doesn't enable greetd; it says how.
install_greeter() {
    local sys_share=/usr/share/cozy-archive sys_fonts=/usr/local/share/fonts/cozy-archive
    local stage; stage="$(mktemp -d)"
    trap 'rm -rf "$stage"' RETURN
    if ! command -v greetd >/dev/null 2>&1; then
        say "greetd isn't installed: sudo pacman -S greetd, then run 'make greeter' again."
        return 1
    fi

    # Who to offer, what to start, the desk, and the greeter's Hyprland, all
    # from tokens.toml and your settings.json (mode, keyboard, wallpaper seed).
    cp -r "$SRC/quickshell" "$stage/quickshell"
    python3 - "$REPO" "$DEST/cozy-archive/settings.json" "$stage" "$USER" <<'PY'
import json, sys
from pathlib import Path
repo, settings, stage, user = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4]
sys.path.insert(0, str(repo / "tools"))
import tokens, wallpaper
t = tokens.load(repo / "tokens.toml")
try:
    s = json.loads(settings.read_text())
except (OSError, ValueError):
    s = {}
seed = int(s.get("wallpaperSeed", 1))
variant = "dvorak" if s.get("keyboard") == "dvorak" else ""    # dvorak-native: the keyboard does it
desk = t.roles[t.mode]["desk"][1:].lower()

qs = stage / "quickshell"
(qs / "greeter.json").write_text(json.dumps({"user": user, "session": "start-hyprland"}, indent=2) + "\n")
# 960×540 at 4× covers a 4K screen; smaller screens show its top-left.
(qs / "greeter-wallpaper.png").write_bytes(wallpaper.draw(t.mode, seed, 960, 540, repo / "tokens.toml"))
(stage / "cozy-archive.lua").write_text(f'''-- Written by `make greeter` (install.sh --greeter); re-run it, don't edit here.
-- A bare Hyprland for greetd's greeter user: it shows the Cozy Archive login
-- card (greeter.qml) and exits once greetd has the session, which starts it.
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -p /usr/share/cozy-archive/quickshell/greeter.qml; pkill -u \\"$(id -u)\\" -x Hyprland")
end)
hl.config({{
    animations = {{ enabled = false }},
    misc  = {{ disable_hyprland_logo = true, disable_splash_rendering = true, background_color = 0xff{desk} }},
    input = {{ kb_layout = "us", kb_variant = "{variant}" }},
}})
''')
PY
    cat > "$stage/config.toml" <<'EOF'
# Written by cozy-archive's `make greeter`.
[terminal]
vt = 1

[default_session]
command = "Hyprland --config /etc/greetd/cozy-archive.lua"
user = "greeter"
EOF

    say "Installing the greeter (sudo)…"
    sudo install -d "$sys_share" /etc/greetd
    sudo rm -rf "$sys_share/quickshell"
    sudo cp -r "$stage/quickshell" "$sys_share/quickshell"
    sudo chmod -R a+rX "$sys_share"
    sudo install -m 644 "$stage/cozy-archive.lua" /etc/greetd/cozy-archive.lua
    if [[ -f /etc/greetd/config.toml ]] && ! sudo cmp -s "$stage/config.toml" /etc/greetd/config.toml; then
        sudo cp /etc/greetd/config.toml "/etc/greetd/config.toml.bak-$STAMP"
        say "Kept the old /etc/greetd/config.toml as config.toml.bak-$STAMP"
    fi
    sudo install -m 644 "$stage/config.toml" /etc/greetd/config.toml

    local user_fonts="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/cozy-archive"
    if [[ -d "$user_fonts" ]]; then
        sudo install -d "$sys_fonts"
        sudo cp "$user_fonts"/* "$sys_fonts/"
        sudo chmod -R a+rX "$sys_fonts"
        sudo fc-cache -f "$sys_fonts" >/dev/null
    else
        say "No brand fonts in $user_fonts yet: run 'make fonts', then 'make greeter' again."
    fi

    say "Greeter installed. To boot into it instead of a TTY login:"
    printf '   sudo systemctl enable greetd   # takes over tty1 at the next boot\n'
    printf '   preview it now, inside the desktop: quickshell -p %s/quickshell/greeter.qml\n' "$sys_share"
}

if [[ "${1:-}" == "--fonts" ]]; then
    install_fonts
    exit 0
fi

if [[ "${1:-}" == "--greeter" ]]; then
    install_greeter
    exit $?
fi

if [[ "${1:-}" == "--colors-only" ]]; then
    # Apps added since the last full install get their directory here.
    [[ -d "$DEST/hypr" && ! -d "$DEST/yazi" ]] && cp -r "$SRC/yazi" "$DEST/yazi" && say "Installed yazi"
    # gen.py --list is relative to the repo: configs/… is the desktop (deployed
    # here); web/ and editors/ are read in place or copied by `make zed`/`vscode`.
    while IFS= read -r path; do
        [[ "$path" == configs/* ]] || continue
        rel="${path#configs/}"
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
    # The color picker saves through here, and keeps the menu's day/night.
    [[ -n "${COZY_KEEP_MODE:-}" ]] || sync_mode
    apply_settings
    say "Colors applied."
    exit 0
fi

# ── Dependency check (informational — won't abort) ──────────────────────────
say "Checking dependencies…"
deps=(Hyprland kitty mako python3 hypridle)
missing=()
for d in "${deps[@]}"; do
    command -v "$d" >/dev/null 2>&1 || missing+=("$d")
done
# Quickshell ships as `quickshell` and/or `qs` depending on the package.
command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || missing+=(quickshell)
if ((${#missing[@]})); then
    printf '   missing: %s\n' "${missing[*]}"
    printf '   Arch: sudo pacman -S hyprland quickshell kitty mako python hypridle\n'
fi

# ── Deploy each config dir, with backup ─────────────────────────────────────
for dir in hypr quickshell kitty mako yazi; do
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
