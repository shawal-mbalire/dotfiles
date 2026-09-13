"""``CachePort`` adapter: one small file per rendered module payload.

Each file starts with a header line ``<timestamp_ms> <ttl_ms>`` followed by the
JSON body. Timestamps come from an injected :class:`TimePort` so the poll path
and refresher share one clock and tests can control it.

This module is imported by the poll client, so it deliberately depends only on
stdlib plus the (typing-only) domain ports.
"""

from __future__ import annotations

import os

if False:  # pragma: no cover - typing only; keeps `typing` off the 50ms poll path
    from domain.ports.core import TimePort

HEADER = " "


class FileCache:
    def __init__(self, directory: str, time: TimePort) -> None:
        self._directory = directory
        self._time = time

    def _path(self, key: str) -> str:
        return os.path.join(self._directory, f"{key}.json")

    def read(self, key: str) -> tuple[str | None, int, int]:
        """Return ``(payload, age_ms, ttl_ms)``; payload is ``None`` when absent."""
        try:
            with open(self._path(key), encoding="utf-8") as handle:
                header = handle.readline().strip()
                payload = handle.read()
        except OSError:
            return None, -1, -1

        parts = header.split(HEADER)
        if len(parts) != 2:
            return payload or None, -1, -1

        try:
            timestamp = int(parts[0])
            ttl_ms = int(parts[1])
        except ValueError:
            return payload or None, -1, -1

        age_ms = self._time.now_ms() - timestamp
        return payload or None, max(age_ms, 0), ttl_ms

    def write(self, key: str, payload: str, ttl_ms: int) -> None:
        """Atomically write a payload header plus body."""
        os.makedirs(self._directory, exist_ok=True)
        path = self._path(key)
        temporary = path + ".tmp"
        with open(temporary, "w", encoding="utf-8") as handle:
            handle.write(f"{self._time.now_ms()} {ttl_ms}\n{payload}")
        os.replace(temporary, path)
