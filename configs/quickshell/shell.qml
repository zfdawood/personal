//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import "bar" as Bar

// Entry point. Everything visual lives in components that read the Theme
// singleton, so the whole desktop restyles from one file.
Scope {
    id: root
    Bar.Bar {}
}
