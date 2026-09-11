"""Driven adapter: night-light process detection and control.

Presence is detected by scanning ``/proc`` (no ``pgrep`` subprocess), so the
polled pill stays fast. Enabling/disabling manages the ``gammastep`` process.
"""

from __future__ import annotations

import os
import shutil
import signal
import subprocess
from pathlib import Path

PROC_ROOT = Path("/proc")


def pids_named(name: str, proc_root: Path = PROC_ROOT) -> list[int]:
    pids: list[int] = []
    for entry in proc_root.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            comm = (entry / "comm").read_text().strip()
        except OSError:
            continue
        if comm == name:
            pids.append(int(entry.name))
    return pids


class GammaStepNightLight:
    def __init__(self, process: str, temperature: str, proc_root: Path = PROC_ROOT) -> None:
        self._process = process
        self._temperature = temperature
        self._proc_root = Path(proc_root)

    def is_available(self) -> bool:
        return shutil.which(self._process) is not None

    def is_active(self) -> bool:
        return bool(pids_named(self._process, self._proc_root))

    def enable(self) -> None:
        subprocess.Popen(
            [self._process, "-O", self._temperature],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    def disable(self) -> None:
        for pid in pids_named(self._process, self._proc_root):
            try:
                os.kill(pid, signal.SIGTERM)
            except OSError:
                continue
