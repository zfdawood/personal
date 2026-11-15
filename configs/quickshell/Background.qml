import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The desk: apply.py draws a low-res wallpaper (tools/wallpaper.py) for the
// current mode and seed and writes its path to ~/.cache/cozy-archive/wallpaper.
// It's shown at exactly Theme.unit× (4×) with no smoothing, so every wallpaper
// pixel is a crisp 4×4 block — one spacing unit — never a blurry or uneven one.
Scope {
    FileView {
        id: pointer
        path: Settings.cacheDir + "/cozy-archive/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "cozy-archive:wallpaper"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.desk            // until the image exists

            Image {
                readonly property string file: pointer.text().trim()
                source: file ? "file://" + file : ""
                cache: false
                smooth: false
                mipmap: false
                width: implicitWidth * Theme.unit
                height: implicitHeight * Theme.unit
            }
        }
    }
}
