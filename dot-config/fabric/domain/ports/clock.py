"""ClockPort — the only source of the current time (TimePort)."""

from __future__ import annotations

from datetime import datetime
from typing import Protocol, runtime_checkable


@runtime_checkable
class ClockPort(Protocol):
    """CONTRACT — ClockPort (TimePort).

    ``now()`` → the current wall-clock time. Injected everywhere so runs are
    reproducible and tests are deterministic. Ticking is a driving concern.
    """

    def now(self) -> datetime: ...
