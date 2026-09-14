import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Shared lock state across every monitor's lock surface, plus the PAM
// authentication conversation (fingerprint first, password fallback).
Scope {
    id: root

    signal unlocked()

    property string currentText: ""
    property string message: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool awaitingResponse: false

    onCurrentTextChanged: showFailure = false

    // Begin the PAM conversation (triggers the fingerprint reader).
    function start() {
        if (pam.active) return;
        root.message = "";
        root.unlockInProgress = true;
        pam.start();
    }

    // Enter: answer a pending prompt, or (re)start the conversation.
    function submit() {
        if (root.awaitingResponse) {
            root.unlockInProgress = true;
            pam.respond(root.currentText);
        } else {
            root.start();
        }
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            root.message = pam.message ?? "";
            root.awaitingResponse = pam.responseRequired;
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
            root.unlockInProgress = false;
        }
    }
}
