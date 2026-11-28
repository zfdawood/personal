import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen: the login card on the desk, on every screen, checked by
// PAM (pam/password.conf). Locked by
//   SUPER+L (SUPER+Shift+L on QWERTY) hyprland.lua
//   loginctl lock-session, sleep     hypridle.conf (lock_cmd, before_sleep_cmd)
// all of which call `quickshell ipc call lock lock`.
//
// If Quickshell dies while locked, the compositor keeps the screen covered in
// a solid color (ext-session-lock), so a crash never unlocks. Recover from a
// TTY with `loginctl unlock-session` or by restarting Quickshell.
Scope {
    id: root

    // What the card shows; every screen's card reads the same state.
    property string buffer: ""
    property string prompt: "Password"
    property bool echo: false
    property string message: ""
    property bool isError: false
    property bool busy: false
    property string answer: ""      // what the user typed, until PAM asks for it

    function lock() {
        if (sessionLock.locked) return
        buffer = ""; message = ""; isError = false; prompt = "Password"; echo = false
        sessionLock.locked = true
    }

    // Enter: start a PAM conversation (or answer its current question).
    function submit() {
        if (pam.active) {
            if (pam.responseRequired) { busy = true; pam.respond(buffer); buffer = "" }
            return
        }
        answer = buffer
        buffer = ""
        busy = true
        if (!pam.start()) {
            busy = false
            message = "Couldn't start PAM (pam/password.conf)."
            isError = true
        }
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (pam.responseRequired) {
                // The first question is the password we already have; any
                // further one (a second factor) is asked on the card.
                if (root.answer !== "") {
                    pam.respond(root.answer)
                    root.answer = ""
                } else {
                    root.busy = false
                    root.prompt = pam.message.replace(/:\s*$/, "") || "Answer"
                    root.echo = pam.responseVisible
                }
            } else if (pam.message) {
                root.message = pam.message
                root.isError = pam.messageIsError
            }
        }

        onCompleted: result => {
            root.busy = false
            root.answer = ""
            root.prompt = "Password"
            root.echo = false
            if (result === PamResult.Success) {
                root.message = ""
                root.isError = false
                sessionLock.locked = false
            } else {
                root.message = result === PamResult.MaxTries ? "Too many tries. Wait a moment."
                             : result === PamResult.Failed ? "Wrong password."
                             : "Couldn't check the password."
                root.isError = true
            }
        }
    }

    // The wallpaper the desktop shows, so the lock looks like the desk with
    // the windows lifted off it.
    FileView {
        id: wallpaper
        path: Settings.cacheDir + "/cozy-archive/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: Theme.desk

            Image {
                readonly property string file: wallpaper.text().trim()
                source: file ? "file://" + file : ""
                cache: false
                smooth: false
                mipmap: false
                width: implicitWidth * Theme.unit
                height: implicitHeight * Theme.unit
            }

            LoginCard {
                id: card
                anchors.centerIn: parent
                user: Quickshell.env("USER")
                prompt: root.prompt
                echo: root.echo
                message: root.message
                isError: root.isError
                busy: root.busy
                buffer: root.buffer
                onBufferEdited: text => root.buffer = text
                onSubmitted: root.submit()
                Component.onCompleted: focusAnswer()
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }
}
