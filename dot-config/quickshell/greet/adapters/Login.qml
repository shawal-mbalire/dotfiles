pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "../infra"

// Driven adapter: the greetd authentication conversation (LoginPort).
// greetd owns PAM (/etc/pam.d/greetd); this drives its IPC: create a session,
// answer each prompt, then launch the chosen session. The UI only renders the
// exposed state and calls start()/submit().
Singleton {
    id: root

    property string currentText: ""
    property string message: ""
    property bool showFailure: false
    property bool awaitingResponse: false
    property bool echoResponse: false

    onCurrentTextChanged: showFailure = false

    // ── LoginPort ─────────────────────────────────────────────────────────
    function start() {
        if (!Greetd.available) {
            root.showFailure = true;
            root.message = "greetd socket is not available";
            return;
        }
        if (Greetd.state === GreetdState.Inactive) {
            root.showFailure = false;
            root.message = "";
            Greetd.createSession(Config.defaultUser);
        }
    }

    // Enter: answer a pending prompt, or (re)start the conversation.
    function submit() {
        if (root.awaitingResponse) {
            Greetd.respond(root.currentText);
            root.currentText = "";
            root.awaitingResponse = false;
        } else {
            root.start();
        }
    }

    function launch() {
        if (Sessions.entries.length === 0) {
            root.showFailure = true;
            root.message = "no session available";
            return;
        }
        Greetd.launch(Sessions.entries[Sessions.selected].argv);
    }

    Connections {
        target: Greetd

        // greetd prompts for a credential. responseRequired is false for
        // informational lines (e.g. "this account is locked"), which we only
        // display.
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.message = message;
            root.awaitingResponse = responseRequired;
            root.echoResponse = echoResponse;
        }

        function onAuthFailure(message) {
            root.currentText = "";
            root.awaitingResponse = false;
            root.showFailure = true;
            root.message = message;
        }

        function onReadyToLaunch() {
            root.launch();
        }

        function onError(error) {
            root.showFailure = true;
            root.message = error;
        }
    }

    Component.onCompleted: start()
}
