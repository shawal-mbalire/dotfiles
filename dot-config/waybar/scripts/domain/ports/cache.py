"""Cache contract: pre-rendered module payloads the poll path can reprint.

``read`` returns ``(payload, age_ms, ttl_ms)`` where ``age_ms``/``ttl_ms`` are
``-1`` when unknown, letting the pure freshness policy in
``domain.workflows.cache`` decide whether a refresh is due.
"""

from __future__ import annotations

from typing import Protocol


class CachePort(Protocol):
    def read(self, key: str) -> tuple[str | None, int, int]: ...

    def write(self, key: str, payload: str, ttl_ms: int) -> None: ...
