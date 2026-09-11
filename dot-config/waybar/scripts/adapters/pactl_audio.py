"""Driven adapter: PulseAudio/PipeWire sink enumeration via ``pactl``."""

from __future__ import annotations

import json
import re
import subprocess

from domain.constants import AUDIO_DESCRIPTION_CODEC, AUDIO_DESCRIPTION_STRIP
from domain.models import AudioSink

_CODEC_PATTERN = re.compile(rf"{re.escape(AUDIO_DESCRIPTION_CODEC)}.*? ")


def shorten_description(description: str) -> str:
    """Strip noisy vendor prefixes from a sink description."""
    shortened = description.replace(AUDIO_DESCRIPTION_STRIP, "")
    shortened = _CODEC_PATTERN.sub("", shortened)
    return shortened.strip() or description


def parse_sinks(payload: str) -> list[AudioSink]:
    data = json.loads(payload)
    sinks: list[AudioSink] = []
    for sink in data:
        name = sink.get("name", "")
        description = shorten_description(sink.get("description", "") or name)
        sinks.append(AudioSink(name=name, description=description))
    return sinks


class PactlAudioDevices:
    def list_sinks(self) -> list[AudioSink]:
        result = subprocess.run(
            ["pactl", "-f", "json", "list", "sinks"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0 or not result.stdout.strip():
            return []
        try:
            return parse_sinks(result.stdout)
        except ValueError:
            return []

    def get_default_sink(self) -> str | None:
        result = subprocess.run(
            ["pactl", "get-default-sink"],
            capture_output=True,
            text=True,
            check=False,
        )
        name = result.stdout.strip()
        return name or None

    def set_default_sink(self, name: str) -> bool:
        result = subprocess.run(
            ["pactl", "set-default-sink", name],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return result.returncode == 0
