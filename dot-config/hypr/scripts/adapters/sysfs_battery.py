"""``BatteryReader`` adapter: battery state from sysfs (subprocess-free)."""

from __future__ import annotations

from pathlib import Path

from domain.models import BatteryStatus

SYSFS_ROOT = Path("/sys/class/power_supply")


class SysfsBattery:
    def __init__(self, supply: str = "BAT0", root: Path = SYSFS_ROOT) -> None:
        self._directory = Path(root) / supply

    def read(self) -> BatteryStatus:
        return BatteryStatus(
            capacity=_read_int(self._directory / "capacity"),
            state=_read_text(self._directory / "status"),
        )


def _read_text(path: Path) -> str | None:
    try:
        return path.read_text().strip()
    except OSError:
        return None


def _read_int(path: Path) -> int | None:
    text = _read_text(path)
    if text is None:
        return None
    try:
        return int(text)
    except ValueError:
        return None
