import QtQuick
import Quickshell
import "domain"
import "infra"
import "adapters"
import "ports"
import "ui"

// Composition root for the login greeter. Quickshell runs under a kiosk
// compositor (cage) started by greetd, shows one fullscreen window, and talks
// to greetd through the Login adapter (adapters/Login.qml, over
// Quickshell.Services.Greetd). It verifies the adapter against its port before
// the greeter is trusted. On launch Quickshell exits and cage follows it, which
// hands the seat to the chosen session.
//
// This config is deployed world-readable to /etc/xdg/quickshell/greet by
// setup/install.sh, because the greeter runs as the `greetd` user and cannot
// read ~/.config (the account's home is 0700).
ShellRoot {
    id: root

    Component.onCompleted: {
        Verify.assertPorts([
            { adapter: Login, methods: Verify.loginPort, name: "LoginPort" }
        ]);
    }

    FloatingWindow {
        id: win

        // cage exposes a single output; fall back to a sane size if the screen
        // list is not populated yet.
        readonly property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

        screen: targetScreen
        implicitWidth: targetScreen ? targetScreen.width : 1280
        implicitHeight: targetScreen ? targetScreen.height : 720
        fullscreen: true
        color: Theme.base
        title: "Login"

        GreetSurface {
            anchors.fill: parent
            context: Login
        }
    }
}
