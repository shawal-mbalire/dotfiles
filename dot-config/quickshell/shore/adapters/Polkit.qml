pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Driven adapter: the session's polkit authentication agent.
// Implements the PolkitPort (submit / cancel) and exposes the active request
// to the prompt UI.
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null && !flow.isCompleted
    readonly property bool registered: agent.isRegistered

    readonly property string message: flow ? flow.message : ""
    readonly property string iconName: flow ? flow.iconName : ""
    readonly property string inputPrompt: flow && flow.inputPrompt !== "" ? flow.inputPrompt : "Password"
    readonly property bool responseVisible: flow ? flow.responseVisible : true
    readonly property bool responseRequired: flow ? flow.isResponseRequired : false
    readonly property string supplementary: flow ? flow.supplementaryMessage : ""
    readonly property bool supplementaryIsError: flow ? flow.supplementaryIsError : false
    readonly property bool failed: flow ? flow.failed : false
    readonly property var identities: flow ? flow.identities : []

    function submit(value) {
        if (flow) flow.submit(value);
    }

    function cancel() {
        if (flow) flow.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
    }
}
