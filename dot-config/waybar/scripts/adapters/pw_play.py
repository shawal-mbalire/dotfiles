"""``SoundPlayer`` adapter using ``pw-play``."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


class PwPlay:
    def __init__(self, command: str = "pw-play") -> None:
        self._command = command

    def play(self, path: str, volume: float = 0.3) -> None:
        if shutil.which(self._command) is None or not Path(path).is_file():
            return
        try:
            subprocess.Popen(
                [self._command, f"--volume={volume}", path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except OSError:
            return
