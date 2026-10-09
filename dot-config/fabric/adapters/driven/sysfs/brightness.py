"""SysfsBrightnessAdapter — BrightnessPort from /sys/class/backlight.

Reads ``brightness``/``max_brightness`` and writes through a native setter.
The default setter writes the kernel sysfs node; a logind setter (D-Bus) is
injected by the composition root when the node is not writable.
"""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path

from adapters.driven.observable import Observable, Poller
from domain.logic import brightness_percent, clamp, raw_from_percent
from domain.models import Brightness

_BACKLIGHT = Path("/sys/class/backlight")


def find_backlight_device(root: Path = _BACKLIGHT) -> Path | None:
    try:
        candidates = sorted(p for p in root.glob("*") if (p / "brightness").exists())
    except OSError:
        return None
    return candidates[0] if candidates else None


def _read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


class SysfsBrightnessAdapter(Observable[Brightness]):
    def __init__(
        self,
        device_dir: Path | None = None,
        *,
        poll_interval: float = 0.5,
        setter: Callable[[int], None] | None = None,
        logger=None,
    ) -> None:
        super().__init__(Brightness())
        self._dir = device_dir or find_backlight_device()
        self._logger = logger
        self._poller = Poller(self._produce, poll_interval)
        self._requested: int | None = None
        self._setter = setter or self._write_sysfs

    def start(self) -> None:
        self._produce()
        self._poller.start()

    def stop(self) -> None:
        self._poller.stop()

    def set_percent(self, percent: int) -> None:
        if self._dir is None:
            self._warn("no backlight device; ignoring set_percent", percent=percent)
            return
        target = int(clamp(round(percent), 0, 100))
        self._requested = target
        self.notify(Brightness(available=True, percent=target))  # optimistic
        try:
            self._setter(target)
        except OSError as exc:
            self._warn("brightness write failed", error=str(exc), percent=target)

    def _write_sysfs(self, percent: int) -> None:
        if self._dir is None:
            return
        max_raw = _read_int(self._dir / "max_brightness") or 0
        raw = raw_from_percent(percent, max_raw)
        (self._dir / "brightness").write_text(str(raw))

    def _produce(self) -> None:
        if self._dir is None:
            self.notify(Brightness(available=False, percent=0))
            return
        max_raw = _read_int(self._dir / "max_brightness") or 0
        raw = _read_int(self._dir / "brightness") or 0
        measured = brightness_percent(raw, max_raw)
        percent = self._requested if self._requested is not None else measured
        if max_raw > 0 and percent == measured:
            self._requested = None
        self.notify(Brightness(available=max_raw > 0, percent=percent))

    def _warn(self, message: str, **context) -> None:
        if self._logger is not None:
            self._logger.warning("brightness", message, **context)
