pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which overlay menu is open. Hyprland binds call these over IPC
// (`quickshell ipc call launcher toggle`); the bar sets them directly.
Singleton {
    id: root
    property bool launcherOpen: false
    property bool settingsOpen: false
    // Survives Quickshell's reload: saving a color rewrites Tokens.qml, which
    // reloads the shell, and the picker should still be open afterwards.
    property alias colorsOpen: persist.colorsOpen

    PersistentProperties {
        id: persist
        reloadableId: "menus"
        property bool colorsOpen: false
    }

    function toggleLauncher() {
        settingsOpen = false; colorsOpen = false
        launcherOpen = !launcherOpen
    }
    function toggleSettings() {
        launcherOpen = false; colorsOpen = false
        settingsOpen = !settingsOpen
    }
    function toggleColors() {
        launcherOpen = false; settingsOpen = false
        colorsOpen = !colorsOpen
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher() }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggleSettings() }
    }
    IpcHandler {
        target: "colors"
        function toggle(): void { root.toggleColors() }
    }
}
