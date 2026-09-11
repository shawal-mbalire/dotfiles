from domain.models import AudioSink
from domain.workflows import audio

from tests.fixtures.fakes import (
    FakeAudioControl,
    FakeAudioDevices,
    FakeBar,
    FakeLogger,
    FakeNotifier,
    FakePrompt,
    FakeSound,
)

SIGNAL = 5


def test_adjust_volume_up_refreshes_and_plays_tone():
    control = FakeAudioControl(volume=40)
    sound, bar, logger = FakeSound(), FakeBar(), FakeLogger()

    audio.adjust_volume(control, "up", 5, sound, "/tone.wav", bar, logger, SIGNAL)

    assert control.adjustments == [5], f"expected [5], got {control.adjustments}"
    assert bar.refreshes == [SIGNAL]
    assert sound.plays == [("/tone.wav", 0.3)]


def test_adjust_volume_down_uses_negative_step():
    control = FakeAudioControl(volume=40)
    audio.adjust_volume(
        control, "down", 5, FakeSound(), "/tone.wav", FakeBar(), FakeLogger(), SIGNAL
    )
    assert control.adjustments == [-5]


def test_toggle_mute_delegates():
    control = FakeAudioControl(muted=False)
    audio.toggle_mute(control, FakeSound(), "/tone.wav", FakeBar(), FakeLogger(), SIGNAL)
    assert control.toggles == 1
    assert control.muted is True


def test_select_device_sets_chosen_sink():
    devices = FakeAudioDevices()
    prompt = FakePrompt(response="Headphones")
    notifier = FakeNotifier()

    audio.select_device(devices, prompt, notifier, FakeLogger())

    assert devices.set_calls == ["sink-b"], f"expected sink-b, got {devices.set_calls}"
    assert ("Audio", "Output: Headphones", "normal") in notifier.notifications


def test_select_device_already_default_is_noop():
    devices = FakeAudioDevices(default="sink-b")
    prompt = FakePrompt(response="Headphones")
    audio.select_device(devices, prompt, FakeNotifier(), FakeLogger())
    assert devices.set_calls == []


def test_select_device_no_sinks_notifies():
    devices = FakeAudioDevices(sinks=[AudioSink(name="", description="")])
    devices._sinks = []
    notifier = FakeNotifier()
    audio.select_device(devices, FakePrompt(), notifier, FakeLogger())
    assert notifier.notifications == [("Audio", "No audio devices found", "normal")]


def test_play_tone_uses_configured_volume():
    sound = FakeSound()
    audio.play_tone(sound, "/tone.wav", FakeLogger())
    assert sound.plays == [("/tone.wav", 0.3)]
