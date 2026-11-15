pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The desktop's runtime settings: ~/.config/cozy-archive/settings.json.
// Quickshell reads it live; every change is written back and handed to
// apply.py, which switches the other apps (Hyprland, kitty, mako, wallpaper).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string dataDir: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || home + "/.cache"

    property alias mode: adapter.mode                 // "light" | "dark"
    property alias keyboard: adapter.keyboard         // "qwerty" | "dvorak" | "dvorak-native"
    property alias clock24h: adapter.clock24h
    property alias wallpaperSeed: adapter.wallpaperSeed

    FileView {
        id: file
        path: root.configDir + "/cozy-archive/settings.json"
        blockWrites: true            // written before apply.py reads it
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: {
            writeAdapter()
            root.apply()
        }

        JsonAdapter {
            id: adapter
            property string mode: Tokens.darkMode ? "dark" : "light"
            property string keyboard: "dvorak-native"
            property bool clock24h: false
            property int wallpaperSeed: 1
        }
    }

    // apply.py, one run at a time; changes made mid-run trigger one more run.
    property bool pending: false
    function apply() {
        if (applier.running) pending = true
        else applier.running = true
    }
    Process {
        id: applier
        command: ["python3", root.dataDir + "/cozy-archive/apply.py"]
        onExited: if (root.pending) {
            root.pending = false
            running = true
        }
    }
}
