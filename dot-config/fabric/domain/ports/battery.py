"""BatteryPort — laptop battery state (read-only)."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Battery
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class BatteryPort(ObservablePort[Battery], Protocol):
    """CONTRACT — BatteryPort (read-only).

    ``read()`` → Battery(present, level 0..100, charging, state, time_text).
    ``state`` ∈ {"Charging","Discharging","Full","Plugged in","Unknown"}.
    """

    def read(self) -> Battery: ...

    def subscribe(self, listener: Listener[Battery]) -> Unsubscribe: ...
