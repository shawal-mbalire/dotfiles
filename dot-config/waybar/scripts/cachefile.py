"""Dependency-light payload cache shared by the poll client and the refresher.

Both the tiny poll client and the full refresh process import this module, so
it deliberately depends only on ``os`` and ``time``. Each cache file looks like::

    <timestamp_ms> <ttl_ms>
    {"text": "...", "tooltip": "..."}

The caller supplies the cache directory (see ``infra.paths``); this module stays
pure I/O. The poll client checks the header to decide whether a background
refresh is needed, then prints the payload verbatim.
"""

from __future__ import annotations

import os
import time

HEADER = " "


def read(cache_dir: str, key: str) -> tuple[str | None, int, int]:
    """Return ``(payload, age_ms, ttl_ms)``; payload is ``None`` when absent."""
    try:
        with open(os.path.join(cache_dir, f"{key}.json"), encoding="utf-8") as handle:
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

    age_ms = int(time.time() * 1000) - timestamp
    return payload or None, max(age_ms, 0), ttl_ms


def write(cache_dir: str, key: str, payload: str, ttl_ms: int) -> None:
    """Atomically write a payload header plus body."""
    os.makedirs(cache_dir, exist_ok=True)
    path = os.path.join(cache_dir, f"{key}.json")
    temporary = path + ".tmp"
    with open(temporary, "w", encoding="utf-8") as handle:
        handle.write(f"{int(time.time() * 1000)} {ttl_ms}\n{payload}")
    os.replace(temporary, path)


def is_stale(age_ms: int, ttl_ms: int) -> bool:
    return ttl_ms >= 0 and age_ms > ttl_ms
