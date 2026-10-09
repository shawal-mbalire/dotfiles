"""LifetimePort — graceful exits and resource cleanup."""

from __future__ import annotations

from collections.abc import Callable
from enum import StrEnum
from typing import Protocol, runtime_checkable


class ExitReason(StrEnum):
    NORMAL = "normal"
    USER = "user"
    ERROR = "error"
    SIGNAL = "signal"
    RELOAD = "reload"


@runtime_checkable
class LifetimePort(Protocol):
    """CONTRACT — LifetimePort.

    Every long-running process and every resource-owning adapter registers
    cleanup here. Cleanup runs exactly once, in reverse registration order,
    whatever the exit reason. No resource is left behind.
    """

    @property
    def reason(self) -> ExitReason: ...

    def on_exit(self, callback: Callable[[ExitReason], None]) -> None:
        """Register a cleanup callback. Idempotent per callback."""
        ...

    def exit(self, reason: ExitReason = ExitReason.NORMAL) -> None:
        """Run all cleanups then stop the loop."""
        ...
