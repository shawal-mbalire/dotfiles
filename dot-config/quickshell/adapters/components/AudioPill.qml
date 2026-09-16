import QtQuick
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

Pill {
    id: root

    readonly property var sink: Audio.defaultSink
    readonly property var audio: Audio.defaultSinkAudio
    readonly property bool muted: audio ? audio.muted : false
    readonly property int volume: audio ? Formatters.percent(audio.volume) : 0

    icon: muted ? Theme.iconVolumeMuted : Theme.iconVolume
    iconColor: muted ? Theme.overlay0 : Theme.sapphire
    text: muted ? "muted" : volume + "%"

    // left: output device menu, right: mute, scroll: volume
    onClicked: UiState.toggleMenu("audio")
    onSecondaryClicked: Audio.toggleMute(root.sink)

    onWheel: delta => Audio.bumpVolume(root.sink, delta * Constants.volumeStep);
}
