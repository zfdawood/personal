//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

// The boot greeter: the same login card as the lock screen (LoginCard.qml),
// checked by greetd instead of PAM. greetd starts a small Hyprland as the
// `greeter` user (/etc/greetd/cozy-archive.lua), which runs
//     quickshell -p /usr/share/cozy-archive/quickshell/greeter.qml
// `make greeter` installs all of it. This file shares the desktop's Theme,
// Card and LoginCard, so the greeter is restyled by the same tokens.
//
// greeter.json, written beside this file by `make greeter`, holds who to
// offer first and what to start:  { "user": "…", "session": "start-hyprland" }
//
// Try it inside a running desktop (no greetd: it says so, and can't log in):
//     quickshell -p configs/quickshell/greeter.qml
ShellRoot {
    id: root

    readonly property string here: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

    property string user: config.user
    property string buffer: ""
    property string prompt: "Password"
    property bool echo: false
    property string message: Greetd.available ? "" : "greetd isn't running here: this is a preview."
    property bool isError: !Greetd.available
    property bool busy: false
    property string answer: ""
    property bool asking: false     // greetd is waiting on an answer typed on the card

    FileView {
        path: root.here + "greeter.json"
        blockLoading: true          // the card picks its first field from `user`
        JsonAdapter {
            id: config
            property string user: ""
            property string session: "start-hyprland"
        }
    }

    function reset(msg, err) {
        busy = false; asking = false; answer = ""
        prompt = "Password"; echo = false
        message = msg; isError = err
    }

    function submit() {
        if (!Greetd.available) return
        if (asking) {
            asking = false; busy = true
            Greetd.respond(buffer); buffer = ""
            return
        }
        if (!user.trim()) { message = "Type a user name first."; isError = true; return }
        answer = buffer
        buffer = ""
        busy = true
        message = ""
        Greetd.createSession(user.trim())
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (root.answer !== "") {
                    Greetd.respond(root.answer)
                    root.answer = ""
                } else {
                    root.busy = false
                    root.asking = true
                    root.prompt = message.replace(/:\s*$/, "") || "Answer"
                    root.echo = echoResponse
                }
            } else {
                root.message = message
                root.isError = error
            }
        }
        function onAuthFailure(message) {
            root.reset("Wrong password.", true)
        }
        function onError(error) {
            Greetd.cancelSession()
            root.reset(error, true)
        }
        function onReadyToLaunch() {
            root.message = "Starting " + config.session + "…"
            root.isError = false
            Greetd.launch(config.session.split(" "), [], true)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool primary: modelData === Quickshell.screens[0]

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "cozy-archive:greeter"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.desk

            // `make greeter` paints one desk for the greeter (it can't read
            // your cache); without it, the plain desk color.
            Image {
                source: "greeter-wallpaper.png"
                cache: false
                smooth: false
                mipmap: false
                width: implicitWidth * Theme.unit
                height: implicitHeight * Theme.unit
            }

            LoginCard {
                visible: win.primary
                anchors.centerIn: parent
                user: root.user
                userEditable: true
                prompt: root.prompt
                echo: root.echo
                message: root.message
                isError: root.isError
                busy: root.busy
                buffer: root.buffer
                hint: "Enter logs in. Tab moves between fields."
                onBufferEdited: text => root.buffer = text
                onUserEdited: name => root.user = name
                onSubmitted: root.submit()
                Component.onCompleted: root.user ? focusAnswer() : focusUser()
            }
        }
    }
}
