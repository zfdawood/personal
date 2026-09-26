#!/usr/bin/env bash
# Run INSIDE the Arch VM (as your normal user, not root) after a base install.
#   ./vm-guest-setup.sh http://192.168.122.1:8099/cozy-archive.tar.gz
# Installs Hyprland + Quickshell (+ deps), fetches the theme from the host,
# deploys it, and drops a Hyprland session you can start with `Hyprland`.
set -euo pipefail

THEME_URL="${1:-}"
c() { printf '\033[38;2;201;123;61m::\033[0m %s\n' "$*"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# ── 1. Official-repo packages ───────────────────────────────────────────────
c "Updating + installing base packages (needs sudo)…"
sudo pacman -Syu --needed --noconfirm \
    hyprland kitty mako hyprpaper wofi \
    git base-devel jq socat \
    qt6-base qt6-declarative qt6-svg qt6-wayland \
    ttf-jetbrains-mono noto-fonts wireplumber

# ── 2. Quickshell from the AUR (compiled here) ──────────────────────────────
if ! command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
    c "Building Quickshell from the AUR (this compiles — give it a few min)…"
    git clone --depth 1 https://aur.archlinux.org/quickshell.git "$tmp/quickshell"
    ( cd "$tmp/quickshell" && makepkg -si --noconfirm )
else
    c "Quickshell already present."
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
  │      Hyprland                                          │
  │  Then: SUPER+Return = kitty · SUPER+Space = launcher   │
  │        SUPER+1..5 = workspaces · SUPER+Q = close       │
  └────────────────────────────────────────────────────────┘
EOF
