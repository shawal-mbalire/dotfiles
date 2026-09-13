"""Driven adapter: PulseAudio/PipeWire sink enumeration via ``pactl``.

``shorten_description`` and ``parse_sinks`` are pure and unit-tested; the class
is thin I/O. The vendor prefix/codec strings are deployment data, injected via
the constructor (see ``infra.config``).
"""

from __future__ import annotations

import json
import re
import subprocess

from domain.models import AudioSink


def compile_codec_pattern(codec: str) -> re.Pattern[str] | None:
    """Compile the noisy-codec matcher, or ``None`` when no codec is configured."""
    if not codec:
        return None
    return re.compile(rf"{re.escape(codec)}.*? ")


def shorten_description(
    description: str,
    strip: str = "",
    codec_pattern: re.Pattern[str] | None = None,
) -> str:
    """Strip noisy vendor prefixes from a sink description."""
    shortened = description.replace(strip, "") if strip else description
    if codec_pattern is not None:
        shortened = codec_pattern.sub("", shortened)
    return shortened.strip() or description


def parse_sinks(
    payload: str,
    strip: str = "",
    codec_pattern: re.Pattern[str] | None = None,
) -> list[AudioSink]:
    data = json.loads(payload)
    sinks: list[AudioSink] = []
    for sink in data:
        name = sink.get("name", "")
        description = shorten_description(sink.get("description", "") or name, strip, codec_pattern)
        sinks.append(AudioSink(name=name, description=description))
    return sinks


class PactlAudioDevices:
    def __init__(
        self,
        description_strip: str = "",
        description_codec: str = "",
        command: str = "pactl",
    ) -> None:
        self._strip = description_strip
        self._codec_pattern = compile_codec_pattern(description_codec)
        self._command = command

    def list_sinks(self) -> list[AudioSink]:
        try:
            result = subprocess.run(
                [self._command, "-f", "json", "list", "sinks"],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return []
        if result.returncode != 0 or not result.stdout.strip():
            return []
        try:
            return parse_sinks(result.stdout, self._strip, self._codec_pattern)
        except ValueError:
            return []

    def get_default_sink(self) -> str | None:
        try:
            result = subprocess.run(
                [self._command, "get-default-sink"],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return None
        name = result.stdout.strip()
        return name or None

    def set_default_sink(self, name: str) -> bool:
        try:
            result = subprocess.run(
                [self._command, "set-default-sink", name],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError:
            return False
        return result.returncode == 0
