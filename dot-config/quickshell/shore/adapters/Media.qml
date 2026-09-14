pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Driven adapter: media players (MediaPort) over MPRIS. Exposes the active
// player so the UI can bind track metadata, and routes transport actions.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var current: root.players.length > 0 ? root.players[0] : null

    // ── MediaPort ─────────────────────────────────────────────────────────
    function previous() {
        if (root.current) root.current.previous();
    }

    function next() {
        if (root.current) root.current.next();
    }

    function togglePlaying() {
        if (root.current) root.current.togglePlaying();
    }
}
