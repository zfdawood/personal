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

    function toggleLauncher() {
        settingsOpen = false
        launcherOpen = !launcherOpen
    }
    function toggleSettings() {
        launcherOpen = false
        settingsOpen = !settingsOpen
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher() }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggleSettings() }
    }
}
