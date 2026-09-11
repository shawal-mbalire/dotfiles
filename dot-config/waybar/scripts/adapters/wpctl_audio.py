"""Driven adapter: PipeWire volume control via ``wpctl``.

``parse_volume_output`` is pure and unit-tested; the class is thin I/O.
"""

from __future__ import annotations

import subprocess

from domain.models import AudioStatus

MIN_VOLUME = 0.0
MAX_VOLUME = 1.0


def parse_volume_output(output: str) -> AudioStatus:
    """Parse ``wpctl get-volume`` output.

    Examples: ``"Volume: 0.26"`` and ``"Volume: 0.26 [MUTED]"``.
    """
    text = output.strip()
    muted = "MUTED" in text.upper()

    percent = 0
    for token in text.replace(":", " ").split():
        try:
            value = float(token)
        except ValueError:
            continue
        if MIN_VOLUME <= value <= MAX_VOLUME:
            percent = int(round(value * 100))
            break

    return AudioStatus(volume_percent=percent, muted=muted)


class WpctlAudioControl:
    def __init__(self, sink: str, max_volume: float = MAX_VOLUME) -> None:
        self._sink = sink
        self._max_volume = max_volume

    def get_status(self) -> AudioStatus:
        result = subprocess.run(
            ["wpctl", "get-volume", self._sink],
            capture_output=True,
            text=True,
            check=False,
        )
        return parse_volume_output(result.stdout)

    def adjust_volume(self, step: int) -> None:
        operator = "+" if step >= 0 else "-"
        subprocess.run(
            [
                "wpctl",
                "set-volume",
                "-l",
                str(self._max_volume),
                self._sink,
                f"{abs(step)}%{operator}",
            ],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def toggle_mute(self) -> None:
        subprocess.run(
            ["wpctl", "set-mute", self._sink, "toggle"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
