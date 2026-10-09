"""SystemRandom — the RandomPort implementation."""

from __future__ import annotations

import random


class SystemRandom:
    """Wraps the standard library RNG. Swap for a seeded adapter in tests."""

    def __init__(self) -> None:
        self._rng = random.Random()

    def random(self) -> float:
        return self._rng.random()
