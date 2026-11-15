#!/usr/bin/env bash
# Run INSIDE the Arch VM (as your normal user, not root) after a base install.
#   ./vm-guest-setup.sh http://10.0.2.2:8099/cozy-archive.tar.gz
# (10.0.2.2 is the host under QEMU user-mode networking, i.e. a libvirt
#  session VM; on the system libvirt NAT network it's 192.168.122.1.)
# Installs Hyprland + Quickshell + Python (+ deps), fetches the theme from the host,
# deploys it, and drops a Hyprland session you can start with `start-hyprland`.
set -euo pipefail

THEME_URL="${1:-}"
c() { printf '\033[38;2;201;123;61m::\033[0m %s\n' "$*"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# ── 1. Packages (Quickshell is in [extra] now; no AUR build needed) ───────
c "Updating + installing packages (needs sudo)…"
sudo pacman -Syu --needed --noconfirm \
    hyprland quickshell kitty mako python \
    git jq socat \
    qt6-base qt6-declarative qt6-svg qt6-wayland \
    ttf-jetbrains-mono noto-fonts wireplumber

# ── 2. Departure Mono (SIL OFL; not packaged in Arch) ──────────────────────
# Before the deploy, so install.sh finds it and copies it into Quickshell.
FONTDIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
if [[ ! -f "$FONTDIR/DepartureMono-Regular.otf" ]]; then
    c "Fetching Departure Mono…"
    DM_URL=https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip
    DM_SHA256=bf3e48059aeef4617ec585bdea81dcc3491c576b3e7a472f52faf40e09ee5c3a
    curl -fL -o "$tmp/dm.zip" "$DM_URL"
    echo "$DM_SHA256  $tmp/dm.zip" | sha256sum -c --quiet
    mkdir -p "$FONTDIR"
    # bsdtar ships with pacman (libarchive), so no unzip needed.
    bsdtar -xOf "$tmp/dm.zip" DepartureMono-1.500/DepartureMono-Regular.otf \
        > "$FONTDIR/DepartureMono-Regular.otf"
    fc-cache -f "$FONTDIR"
else
    c "Departure Mono already installed."
fi

# ── 3. Fetch + deploy the theme ─────────────────────────────────────────────
if [[ -n "$THEME_URL" ]]; then
    c "Fetching theme from $THEME_URL"
    # Unpack into the temp dir so an existing ~/cozy-archive (e.g. a git clone)
    # is never touched.
    curl -fL -o "$tmp/cozy-archive.tar.gz" "$THEME_URL"
    tar xzf "$tmp/cozy-archive.tar.gz" -C "$tmp"   # extracts to $tmp/cozy-archive/
    c "Deploying via install.sh"
    ( cd "$tmp/cozy-archive" && ./install.sh )
else
    c "No theme URL given — skipping deploy. (Pass the host URL as arg 1.)"
fi

cat <<'EOF'

  ┌─ next ────────────────────────────────────────────────┐
  │  Start the desktop from this TTY:                      │
  │      start-hyprland                                    │
  │  SUPER+Return = kitty      SUPER+Space = launcher      │
  │  SUPER+comma = settings    SUPER+Q = close window      │
  └────────────────────────────────────────────────────────┘
EOF
