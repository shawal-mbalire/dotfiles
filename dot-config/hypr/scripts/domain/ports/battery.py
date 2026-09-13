"""Battery ports: read the battery and track which thresholds fired."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import BatteryStatus


@runtime_checkable
class BatteryReader(Protocol):
    def read(self) -> BatteryStatus: ...


@runtime_checkable
class SentMarkerStore(Protocol):
    """Remember which notifications already fired for the current state."""

    def reset_for_state(self, state: str) -> None: ...

    def claim(self, marker: str) -> bool:
        """Return True exactly once per marker per state (then mark it sent)."""
