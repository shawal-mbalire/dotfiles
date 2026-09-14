pragma Singleton

import QtQuick
import Quickshell

// Infrastructure: deployment-specific values for the greeter. The only place in
// the greeter that knows about the host.
Singleton {
    // The account offered on the login form. greetd authenticates this user.
    readonly property string defaultUser: "shawal"

    // Wallpaper shared with the session shell. shore copies its current
    // wallpaper here on every change (see shore/adapters/Wallpaper.qml); the
    // directory is owned by the desktop user and readable by the greetd user,
    // so the login screen always matches the desktop without touching
    // ~/wallpapers (which is 0700 and unreadable before login).
    readonly property string wallpaper: "/var/lib/greetd/wallpaper/current"

    // Sessions offered in the picker, read from the standard directory.
    readonly property string sessionsDir: "/usr/share/wayland-sessions"

    // Session preselected by name match; the user can change it per login for
    // one-off diagnosis. Matched case-insensitively against the .desktop Name.
    readonly property string defaultSession: "Hyprland"
}
