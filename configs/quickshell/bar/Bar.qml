import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// One top bar per screen. Parchment/umber casing with a thick bottom edge,
// square everything. Left: workspace squares. Center: mono clock. Right:
// instrument-panel meters (cpu / ram / vol) + a "system nominal" square.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "cozy-archive:bar"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: Theme.bgPrimary

            // ── thick bottom edge (equipment casing) ──
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.borderWidth
                color: Theme.border
            }

            // ── content ──
            Item {
                anchors.fill: parent
                anchors.leftMargin: Theme.gap
                anchors.rightMargin: Theme.gap
                anchors.bottomMargin: Theme.borderWidth   // center above the bottom edge

                Workspaces {
                    id: ws
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    screenName: bar.screen.name
                }

                Clock {
                    anchors.centerIn: parent
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.gap + 4

                    BarMeter {
                        label: "cpu"
                        value: Sys.cpu
                        fillColor: value > 0.85 ? Theme.warning
                                 : value > 0.6  ? Theme.accent
                                 : Theme.good
                    }
                    BarMeter {
                        label: "ram"
                        value: Sys.mem
                        fillColor: value > 0.85 ? Theme.warning : Theme.accent
                    }
                    BarMeter {
                        label: "vol"
                        value: Audio.muted ? 0 : Audio.volume
                        fillColor: Audio.muted ? Theme.textTertiary : Theme.media
                    }

                    StatusDot {
                        anchors.verticalCenter: parent.verticalCenter
                        tint: Theme.good      // "everything is fine" signal
                    }
                }
            }

            // ── optional CRT scanline overlay (off by default) ──
            Rectangle {
                anchors.fill: parent
                visible: Theme.scanlines
                opacity: Theme.scanlineOpacity
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.scanline }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.scanline }
                }
            }
        }
    }
}
