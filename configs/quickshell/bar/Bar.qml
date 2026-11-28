import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// One bar per screen: a parchment card lying on the desk, like the windows
// below it — same cut corners, same bevel lit from the top left, same hard
// shadow, same 8px gap. Click the clock for settings.
// Left: workspaces. Center: date and time. Right: cpu / ram / vol meters.
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

            // The surface is transparent desk-space: an 8px margin, the card,
            // and room for the card's shadow to fall below it.
            color: "transparent"
            implicitHeight: Theme.gap + Theme.barHeight + Theme.shadowOffset

            // Windows start gaps_out (8px) below this line — the card's bottom
            // edge — so card → window is the same 8px as window → window. The
            // shadow hangs into that gap, exactly as a window's does.
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Theme.gap + Theme.barHeight

            // ── the card (draws its own hard shadow) ──
            Card {
                id: card
                x: Theme.gap
                y: Theme.gap
                width: parent.width - 2 * Theme.gap
                height: Theme.barHeight
                fillAlpha: Theme.barAlpha      // tokens.toml alpha

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.padX - Theme.borderWidth   // Card already insets the border
                    anchors.rightMargin: Theme.padX - Theme.borderWidth

                    Workspaces {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        screenName: bar.screen.name
                    }

                    Clock {
                        anchors.centerIn: parent
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Menus.toggleSettings()   // same as SUPER+comma
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.groupGap

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
}
