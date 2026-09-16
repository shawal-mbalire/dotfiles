import QtQuick
import ".."
import "../../domain"
import "../../domain"
import "../../adapters"

// Driving adapter: watches the default sink and raises the volume OSD. Keeps
// this presentation logic out of the composition root, which only wires it.
Item {
    id: root

    Connections {
        target: Audio.defaultSinkAudio
        function onVolumeChanged() {
            root.show();
        }
        function onMutedChanged() {
            root.show();
        }
    }

    function show() {
        const sink = Audio.defaultSink;
        if (!sink || !sink.audio) return;
        UiState.showOsd(
            sink.audio.muted ? Theme.iconVolumeMuted : Theme.iconVolume,
            sink.audio.volume,
            sink.audio.muted ? "muted" : Formatters.percent(sink.audio.volume) + "%"
        );
    }
}
