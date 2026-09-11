"""``SoundPlayer`` adapter using ``pw-play``."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


class PwPlay:
    def play(self, path: str, volume: float = 0.3) -> None:
        if shutil.which("pw-play") is None or not Path(path).is_file():
            return
        subprocess.Popen(
            ["pw-play", f"--volume={volume}", path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
