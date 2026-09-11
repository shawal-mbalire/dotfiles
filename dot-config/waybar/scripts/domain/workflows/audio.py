"""Audio workflows: device selection, volume keys and feedback tone."""

from __future__ import annotations

from domain.constants import VOLUME_TONE_VOLUME
from domain.ports.audio import AudioControl, AudioDevices
from domain.ports.core import BarGateway, Logger, Notifier, Prompt, SoundPlayer


def select_device(
    devices: AudioDevices,
    prompt: Prompt,
    notifier: Notifier,
    logger: Logger,
) -> None:
    sinks = devices.list_sinks()
    if not sinks:
        notifier.notify("Audio", "No audio devices found")
        return

    default_name = devices.get_default_sink()
    lines = [sink.menu_label for sink in sinks]
    chosen = prompt.choose(lines, "Choose Audio")
    if not chosen:
        return

    chosen_sink = next(
        (sink for sink in sinks if sink.menu_label == chosen),
        next((sink for sink in sinks if sink.description == chosen.removesuffix("  ✓")), None),
    )
    if chosen_sink is None:
        return

    if chosen_sink.name == default_name:
        return

    if devices.set_default_sink(chosen_sink.name):
        logger.info(f"audio default sink -> {chosen_sink.name}")
        notifier.notify("Audio", f"Output: {chosen_sink.description}")
    else:
        notifier.notify("Audio", f"Failed to switch: {chosen_sink.description}", "critical")


def adjust_volume(
    control: AudioControl,
    direction: str,
    step: int,
    sound: SoundPlayer,
    tone_path: str,
    bar: BarGateway,
    logger: Logger,
    signal: int,
) -> None:
    delta = step if direction == "up" else -step
    control.adjust_volume(delta)
    bar.refresh(signal)
    sound.play(tone_path, VOLUME_TONE_VOLUME)
    logger.debug(f"audio volume {direction} by {step}")


def toggle_mute(
    control: AudioControl,
    sound: SoundPlayer,
    tone_path: str,
    bar: BarGateway,
    logger: Logger,
    signal: int,
) -> None:
    control.toggle_mute()
    bar.refresh(signal)
    sound.play(tone_path, VOLUME_TONE_VOLUME)
    logger.debug("audio mute toggled")


def play_tone(sound: SoundPlayer, tone_path: str, logger: Logger) -> None:
    logger.debug(f"play tone {tone_path}")
    sound.play(tone_path, VOLUME_TONE_VOLUME)
