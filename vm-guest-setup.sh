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
    hyprland quickshell kitty mako python yazi file hypridle greetd \
    git jq socat \
    qt6-base qt6-declarative qt6-svg qt6-wayland \
    ttf-jetbrains-mono noto-fonts wireplumber

# ── 2. Fonts ──────────────────────────────────────────────────────────────
# install.sh fetches the brand's faces (tokens.toml [type]) itself, skipping
# any that are already installed (ttf-jetbrains-mono above covers the mono).

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
  │  SUPER+E = files (yazi)      SUPER+L = lock             │
  └────────────────────────────────────────────────────────┘
EOF
