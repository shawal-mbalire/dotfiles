"""BrightnessPort — panel backlight."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Brightness
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class BrightnessPort(ObservablePort[Brightness], Protocol):
    """CONTRACT — BrightnessPort (backlight).

    ``read()`` → Brightness(available, percent 0..100).

    Commands:
      set_percent(percent)
        Pre:  percent is finite.
        Post: percent == clamp(round(percent), 0, 100) immediately (optimistic)
              and after the device confirms; rapid calls coalesce, last wins.
    """

    def read(self) -> Brightness: ...

    def subscribe(self, listener: Listener[Brightness]) -> Unsubscribe: ...

    def set_percent(self, percent: int) -> None: ...
