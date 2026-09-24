pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default audio sink exposed as a simple {volume, muted} pair for the bar meter.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null

    readonly property real volume: audio?.volume ?? 0.0
    readonly property bool muted: audio?.muted ?? false

    // Keep the sink's PipeWire object bound/tracked so `audio` stays live.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
