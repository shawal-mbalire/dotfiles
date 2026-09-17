pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Driven adapter: the session lock's authentication (AuthPort).
// Owns the PAM conversation (fingerprint first, password fallback via pam.conf)
// and shared lock state across every monitor. The lock surface renders it; the
// composition root reacts to `unlocked`.
Singleton {
    id: root

    signal unlocked()

    property string currentText: ""
    property string message: ""
    property bool showFailure: false
    property bool unlockInProgress: false
    property bool awaitingResponse: false
    property bool _autoRespond: false

    onCurrentTextChanged: showFailure = false

    // ── AuthPort ──────────────────────────────────────────────────────────
    // Begin the PAM conversation (triggers the fingerprint reader).
    function start() {
        if (pam.active) return;
        root.message = "";
        root.unlockInProgress = true;
        root._autoRespond = false;
        pam.start();
    }

    // TEMP: bypass PAM to escape a stuck lock screen
    function forceUnlock() {
        pam.cancel();
        root.currentText = "";
        root.showFailure = false;
        root.awaitingResponse = false;
        root.unlockInProgress = false;
        root.message = "";
        root.unlocked();
    }

    // Enter: answer a pending prompt, or (re)start the conversation.
    function submit() {
        if (root.awaitingResponse) {
            root.unlockInProgress = true;
            pam.respond(root.currentText);
        } else if (pam.active && root.currentText.length > 0) {
            // User typed a password while fingerprint reader is active.
            // Cancel fingerprint so PAM falls through to the password rule.
            root._autoRespond = true;
            pam.cancel();
            restartTimer.restart();
        } else {
            root.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 50
        onTriggered: {
            if (root._autoRespond && !pam.active) {
                root.start();
            }
        }
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath(".")
        config: "pam.conf"

        onPamMessage: {
            root.message = pam.message ?? "";
            root.awaitingResponse = pam.responseRequired;
            if (root._autoRespond && pam.responseRequired && root.currentText.length > 0) {
                root._autoRespond = false;
                root.unlockInProgress = true;
                pam.respond(root.currentText);
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.currentText = "";
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
                root.awaitingResponse = false;
            }
            root._autoRespond = false;
            root.unlockInProgress = false;
        }
    }
}
