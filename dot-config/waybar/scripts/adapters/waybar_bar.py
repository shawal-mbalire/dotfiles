"""``BarGateway`` adapter: nudge waybar to re-run a module.

Waybar's custom modules listen for ``SIGRTMIN+<signal>``. Rather than shelling
out to ``pgrep`` (slow), we scan ``/proc`` directly.
"""

from __future__ import annotations

import os
import signal
from pathlib import Path

PROC_ROOT = Path("/proc")


def waybar_pids(proc_root: Path = PROC_ROOT) -> list[int]:
    pids: list[int] = []
    for entry in proc_root.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            comm = (entry / "comm").read_text().strip()
        except OSError:
            continue
        if comm == "waybar":
            pids.append(int(entry.name))
    return pids


class WaybarBar:
    def refresh(self, signal_offset: int) -> None:
        signum = signal.SIGRTMIN + signal_offset
        for pid in waybar_pids():
            try:
                os.kill(pid, signum)
            except OSError:
                continue
