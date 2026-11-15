//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import "bar" as Bar
import "menus" as Overlay

// Entry point. Everything visual lives in components that read the Theme
// singleton, so the whole desktop restyles from one file.
//   Background   the desk wallpaper (one per screen)
//   Bar          the top bar (one per screen)
//   Launcher     SUPER+Space
//   SettingsPanel SUPER+comma, or click the clock
Scope {
    id: root
    Background {}
    Bar.Bar {}
    Overlay.Launcher {}
    Overlay.SettingsPanel {}
}
