import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../../domain"
import "../../infra"
import "../../adapters"

Pill {
    id: root

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property int volume: audio ? Formatters.percent(audio.volume) : 0

    icon: muted ? Theme.iconVolumeMuted : Theme.iconVolume
    iconColor: muted ? Theme.overlay0 : Theme.sapphire
    text: muted ? "muted" : volume + "%"

    // left: output device menu, right: mute, scroll: volume
    onClicked: UiState.toggleMenu("audio")
    onSecondaryClicked: if (audio) audio.muted = !audio.muted

    onWheel: delta => {
        if (audio) audio.volume = Math.max(0, Math.min(1, audio.volume + delta * Constants.volumeStep));
    }
}
