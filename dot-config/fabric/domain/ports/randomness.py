"""RandomPort — the only source of randomness."""

from __future__ import annotations

from typing import Protocol, runtime_checkable


@runtime_checkable
class RandomPort(Protocol):
    """CONTRACT — RandomPort.

    ``random()`` → a float in [0, 1). Injected so behaviour is reproducible.
    """

    def random(self) -> float: ...
