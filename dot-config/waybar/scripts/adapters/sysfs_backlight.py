"""Driven adapter: backlight reads from sysfs, writes via ``brightnessctl``.

Reading ``/sys/class/backlight`` is instantaneous, so the polled pill stays
inside the budget. Changing the level needs the udev/polkit helper.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

SYSFS_ROOT = Path("/sys/class/backlight")


def _read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


class SysfsBacklight:
    def __init__(self, device: str = "", root: Path = SYSFS_ROOT) -> None:
        self._root = Path(root)
        self._device = device

    def _device_dir(self) -> Path | None:
        if self._device and (self._root / self._device).is_dir():
            return self._root / self._device
        candidates = sorted(path for path in self._root.glob("*") if path.is_dir())
        return candidates[0] if candidates else None

    def get_percent(self) -> int:
        directory = self._device_dir()
        if directory is None:
            return 0
        current = _read_int(directory / "brightness")
        maximum = _read_int(directory / "max_brightness")
        if current is None or not maximum:
            return 0
        return round(current * 100 / maximum)

    def set_relative(self, delta: int) -> None:
        if delta == 0:
            return
        operator = "+" if delta > 0 else "-"
        subprocess.run(
            ["brightnessctl", "s", f"{abs(delta)}%{operator}"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def set_percent(self, percent: int) -> None:
        subprocess.run(
            ["brightnessctl", "s", f"{percent}%"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
