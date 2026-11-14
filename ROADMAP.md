# Roadmap

What a CLI-first daily driver needs from the desktop, and where Cozy Archive
stands. Not a full DE: the bar should tell you what you'd otherwise have to
open a terminal to find out, keys should do what laptop keys do, and the
session should lock, sleep, and shut down properly. A CLI tool is a perfectly
good answer wherever one is listed.

`[x]` done · `[~]` partial · `[ ]` not started

> **Not yet verified in a live session:** the Quickshell/Hyprland changes since
> the first build (token-driven `Tokens.qml`, per-monitor workspaces, CPU
> fix). Boot the VM before building on them.

## Tier 1: before daily-driving it

Things whose absence you'd notice on day one.

### Session & power
- [ ] **Lock screen**: `hyprlock`, styled from tokens
- [ ] **Idle handling**: `hypridle` (dim → lock → suspend; lock before sleep)
- [ ] **Power menu**: lock / suspend / logout / reboot / shutdown. Today
      `SUPER+M` exits Hyprland instantly with no confirmation
- [ ] **Polkit agent**: `hyprpolkitagent`; without one, GUI password
      prompts (mounting, `pkexec`, some installers) silently fail
- [ ] **Portals**: `xdg-desktop-portal-hyprland` + `-gtk` for screen sharing
      and file pickers (browser video calls need this)

### Bar: status at a glance
- [x] Workspaces (numbered squares, per-monitor active)
- [x] Clock
- [x] CPU / RAM meters
- [x] Volume meter (display only)
- [ ] **Battery**: level + charging state, warning color when low;
      `Quickshell.Services.UPower`; hidden on machines without one
- [ ] **Network**: connected / SSID / down (NetworkManager); `nmtui` for
      changes is fine
- [~] **Status dot**: currently a static "all good" placeholder. Wire it to
      something real (low battery, no network, failed systemd units…)

### Keys that should just work
- [ ] **Volume keys**: `XF86Audio{Raise,Lower}Volume`, `XF86AudioMute` →
      `wpctl` (no XF86 bindings exist yet)
- [ ] **Brightness keys**: `brightnessctl` (laptop)
- [ ] **Media keys**: play/pause/next → `playerctl`
- [ ] **Screenshots**: region + full screen to file and clipboard;
      `grim` + `slurp` + `wl-copy`
- [ ] **Clipboard**: `wl-clipboard` so CLI tools can copy/paste on Wayland

### Theming gaps you'll hit immediately
- [ ] **GTK / Qt apps**: file pickers and any GUI app render in stock
      Adwaita. Set GTK theme + `qt6ct`, generated from tokens where possible
- [ ] **Cursor theme**: consistent cursor across apps (`hyprcursor` /
      `XCURSOR_THEME`)
- [~] **Launcher**: wofi works but is unstyled; generate its CSS from tokens

## Tier 2: soon after

Rough edges that become annoying within a week.

- [ ] **OSD popups** for volume / brightness changes (Quickshell)
- [ ] **Do-not-disturb** toggle: `makoctl mode -t do-not-disturb` on a key,
      shown in the bar
- [ ] **Notification history**: `makoctl history` / restore-last on a key;
      a full notification-center panel is optional
- [ ] **Runtime day/night toggle**: a key (or sunset timer) that flips mode
      without editing `tokens.toml`
- [ ] **Night light**: `hyprsunset`; pairs naturally with night mode
- [ ] **Monitor config**: real `monitor=` lines + workspace-to-monitor rules
      (currently `preferred,auto`)
- [ ] **Bar interactions**: scroll on the volume meter to adjust, click to mute
- [ ] **System tray**: `Quickshell.Services.SystemTray`, for apps that live
      there (chat clients, Steam, VPNs)
- [ ] **File manager**: `SUPER+E` launches nautilus, which isn't installed or
      themed. Either install + theme it, or bind a TUI (e.g. `yazi` in kitty)
- [ ] **Departure Mono**: fetch automatically in `install.sh` instead of
      printing instructions

## Tier 3: optional

- [ ] Calendar popup on clock click
- [ ] Now-playing (MPRIS) in the bar
- [ ] Bluetooth status (+ `bluetuith` for management)
- [ ] Clipboard history (`cliphist`)
- [ ] Screen recording (`wf-recorder`)
- [ ] Color picker (`hyprpicker`), handy for palette work
- [ ] Removable-media automount (`udiskie`)
- [ ] Wallpaper image (hyprpaper is already wired, just empty)
- [ ] Display manager / autologin (`greetd` + `tuigreet` fits a CLI setup);
      today you start `start-hyprland` from a TTY
- [ ] Keyboard-layout indicator (only matters with multiple layouts)
- [ ] Colorblind-safe role set in `tokens.toml` (components already ask for
      `warning` / `good`, not specific hues)

## Done

- [x] Hyprland: square, 2px amber borders, no blur/shadow, crisp animations,
      vim + arrow focus, workspaces 1–5
- [x] Quickshell bar: workspaces, clock, CPU/RAM/volume meters, status dot
- [x] kitty, mako themed
- [x] Design tokens: `tokens.toml` → Quickshell, Hyprland, kitty, mako
- [x] Day / night palettes with one switch (`mode`) + `make colors`
- [x] WCAG contrast checks on every text color, both modes, as a pre-commit hook
- [x] Installer with backups, symlink-safe; colors-only redeploy
