"""System status contracts: brightness, night light, network, battery."""

from __future__ import annotations

from typing import Protocol

from domain.models import BatteryStatus, NetworkStatus


class BrightnessGateway(Protocol):
    def get_percent(self) -> int: ...

    def set_relative(self, delta: int) -> None: ...

    def set_percent(self, percent: int) -> None: ...


class NightLightGateway(Protocol):
    def is_available(self) -> bool: ...

    def is_active(self) -> bool: ...

    def enable(self) -> None: ...

    def disable(self) -> None: ...


class NetworkGateway(Protocol):
    def status(self) -> NetworkStatus: ...


class BatteryGateway(Protocol):
    def status(self) -> BatteryStatus: ...
