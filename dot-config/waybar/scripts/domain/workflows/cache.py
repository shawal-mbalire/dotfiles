"""Pure cache-freshness policy. No I/O — just the decision."""

from __future__ import annotations


def is_stale(age_ms: int, ttl_ms: int) -> bool:
    """True when a cached payload is older than its TTL.

    ``ttl_ms < 0`` means "unknown TTL" and is treated as never stale, matching
    the poll client's tolerant behaviour on corrupt cache headers.
    """
    return ttl_ms >= 0 and age_ms > ttl_ms
