import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Shared lock state across every monitor's lock surface, plus the PAM
// authentication conversation.
Scope {
    id: root

    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "" || unlockInProgress) return;
        unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: if (responseRequired) respond(root.currentText)

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.currentText = "";
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }
    }
}
