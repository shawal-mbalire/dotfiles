"""Audio contracts: volume control and output-device selection."""

from __future__ import annotations

from typing import Protocol

from domain.models import AudioSink, AudioStatus


class AudioControl(Protocol):
    def get_status(self) -> AudioStatus: ...

    def adjust_volume(self, step: int) -> None: ...

    def toggle_mute(self) -> None: ...


class AudioDevices(Protocol):
    def list_sinks(self) -> list[AudioSink]: ...

    def get_default_sink(self) -> str | None: ...

    def set_default_sink(self, name: str) -> bool: ...
