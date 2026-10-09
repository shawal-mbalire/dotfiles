"""SysfsBatteryAdapter — BatteryPort from /sys/class/power_supply.

Polls the kernel interface (there is no portable event source); mapping is pure.
"""

from __future__ import annotations

from pathlib import Path

from adapters.driven.observable import Observable, Poller
from domain.logic import battery_from_capacity
from domain.models import Battery

_POWER_SUPPLY = Path("/sys/class/power_supply")


def _read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def _read_str(path: Path) -> str:
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def find_battery_device(root: Path = _POWER_SUPPLY) -> Path | None:
    """Return the first laptop battery directory, or None."""
    try:
        candidates = sorted(p for p in root.glob("BAT*") if p.is_dir())
    except OSError:
        return None
    for candidate in candidates:
        if (candidate / "capacity").exists() or (candidate / "energy_full").exists():
            return candidate
    return candidates[0] if candidates else None


class SysfsBatteryAdapter(Observable[Battery]):
    def __init__(
        self, device_dir: Path | None = None, poll_interval: float = 2.0, logger=None
    ) -> None:
        super().__init__(Battery())
        self._dir = device_dir or find_battery_device()
        self._logger = logger
        self._poller = Poller(self._produce, poll_interval)

    def start(self) -> None:
        self._produce()
        self._poller.start()

    def stop(self) -> None:
        self._poller.stop()

    def _produce(self) -> None:
        if self._dir is None:
            self.notify(Battery(present=False, state="Unknown", time_text=""))
            return
        present = _read_int(self._dir / "present")
        present_now = present != 0 if present is not None else True
        capacity = _read_int(self._dir / "capacity")
        if capacity is None:
            energy_now = _read_int(self._dir / "energy_now")
            energy_full = _read_int(self._dir / "energy_full")
            if energy_now is not None and energy_full:
                capacity = round(energy_now * 100 / energy_full)
        status = _read_str(self._dir / "status")
        to_empty = _read_int(self._dir / "time_to_empty_now") or 0
        to_full = _read_int(self._dir / "time_to_full_now") or 0
        reading = battery_from_capacity(present_now, capacity or 0, status, to_empty, to_full)
        self.notify(reading)

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("battery", message, **context)
