"""SystemClock — the TimePort implementation."""

from __future__ import annotations

from datetime import datetime


class SystemClock:
    """Returns the real wall-clock time. Swap for a frozen clock in tests."""

    def now(self) -> datetime:
        return datetime.now()
