"""Pure data structures for the hypr helper scripts.

Standard library only: the domain never imports a framework, adapter, or
external command.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum


class BatteryState(StrEnum):
    """Charging states reported by sysfs ``status``."""

    CHARGING = "Charging"
    DISCHARGING = "Discharging"
    FULL = "Full"


@dataclass(frozen=True)
class BatteryStatus:
    """Battery capacity and state, either of which may be unavailable."""

    capacity: int | None = None
    state: str | None = None


@dataclass(frozen=True)
class BatteryNotification:
    """One threshold notification: a stable marker plus its presentation."""

    marker: str
    summary: str
    body_template: str
    urgency: str
    icon: str

    def body(self, capacity: int) -> str:
        """Render the body for a given capacity."""
        return self.body_template.format(capacity=capacity)


@dataclass(frozen=True)
class Monitor:
    """A monitor as reported by the compositor."""

    name: str
    width: int | None = None
    mirror_of: str | None = None


@dataclass(frozen=True)
class MonitorRule:
    """A monitor rule to apply (the compositor-facing DTO shape)."""

    output: str
    mode: str
    position: str
    scale: int
    mirror: str | None = None
